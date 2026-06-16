"use strict";

const functions = require("firebase-functions"); // for HttpsError fallback usage
const admin = require("firebase-admin");
const axios = require("axios");

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { DateTime } = require("luxon");

const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { v4: uuidv4 } = require("uuid");

const logger = require("firebase-functions/logger");


admin.initializeApp();
const db = admin.firestore();

// Read from .env
const WHATSAPP_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const WHATSAPP_PHONE_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const APP_LINK = process.env.WHATSAPP_APP_LINK || "https://yourapp.com/download";


// cloudfare keys . 
const R2_ACCOUNT_ID = process.env.R2_ACCOUNT_ID;
const R2_ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const R2_SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY;
const R2_BUCKET = process.env.R2_BUCKET;

if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY || !R2_BUCKET) {
  console.warn("⚠️ R2 env vars missing. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET");
}

const r2 = new S3Client({
  region: "auto",
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});


/**
 * -------------------------
 * Helpers (FCM)
 * -------------------------
 */

// Your recommended user doc format:
// users/{uid}: { fcmTokens: { "<token>": true, ... }, rsvpDocId, activeWeddingId }
async function getUserTokensByRsvp(weddingId, rsvpDocId) {
  const usersSnap = await db
    .collection("users")
    .where("activeWeddingId", "==", weddingId)
    .where("rsvpDocId", "==", rsvpDocId)
    .limit(5) // just in case duplicates exist, we collect from up to 5
    .get();

  if (usersSnap.empty) return [];

  const tokens = [];
  usersSnap.docs.forEach((d) => {
    const data = d.data() || {};
    const tokenMap = data.fcmTokens || {};
    Object.keys(tokenMap).forEach((t) => {
      if (tokenMap[t]) tokens.push(t);
    });
  });

  return tokens;
}

async function sendToTokens(tokens, payload) {
  if (!tokens || tokens.length === 0) {
    return { successCount: 0, failureCount: 0 };
  }

  // FCM multicast limit = 500 tokens per request
  const chunkSize = 500;
  let totalSuccess = 0;
  let totalFailure = 0;

  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);

    const res = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: payload.notification, // {title, body}
      data: payload.data || {}, // always strings
    });

    totalSuccess += res.successCount;
    totalFailure += res.failureCount;

    // (Optional) log token errors
    res.responses.forEach((r, idx) => {
      if (!r.success) {
        console.log("FCM send error:", {
          token: chunk[idx],
          error: r.error?.message,
        });
      }
    });
  }

  return { successCount: totalSuccess, failureCount: totalFailure };
}

/**
 * Parse event ISO string like: "2026-02-11T17:00:00+05:30"
 * This preserves the offset zone.
 */
function parseEventDateTime(isoString) {
  const dt = DateTime.fromISO(isoString, { setZone: true });
  return dt.isValid ? dt : null;
}

/**
 * Compute morning trigger time: 9:00 AM on same event date (local zone).
 * If you store wedding.timeZone, it will use that zone instead (recommended).
 */
function computeMorningTrigger(eventStartDt, weddingTimeZone) {
  const zoned = weddingTimeZone
    ? eventStartDt.setZone(weddingTimeZone)
    : eventStartDt; // uses offset from ISO if no explicit zone

  return zoned.set({ hour: 9, minute: 0, second: 0, millisecond: 0 });
}


//cloudfare helpers

function normalizePhone(phone) {
  return String(phone || "").replace(/[\s-]/g, "");
}

function detectTypeFromMime(mimeType) {
  const mt = String(mimeType || "").toLowerCase();
  return mt.startsWith("video/") ? "video" : "image";
}

function extFromMime(mimeType) {
  const mt = String(mimeType || "").toLowerCase();
  if (mt === "image/jpeg") return "jpg";
  if (mt === "image/png") return "png";
  if (mt === "image/heic" || mt === "image/heif") return "heic";
  if (mt === "video/mp4") return "mp4";
  if (mt === "video/quicktime") return "mov";
  if (mt === "video/x-m4v") return "m4v";
  return "";
}

function buildR2Key({ weddingId, eventId, uid, mediaId, mimeType }) {
  const type = detectTypeFromMime(mimeType);
  const ext = extFromMime(mimeType);
  const base = `weddings/${weddingId}/events/${eventId}/users/${uid}/${type}/${mediaId}`;
  return ext ? `${base}.${ext}` : base;
}

// ✅ Your rule: only invited guests (RSVP phone exists) can upload/view
async function assertInvitedByPhone(weddingId, phone) {
  const p = normalizePhone(phone);
  if (!p) throw new HttpsError("permission-denied", "Phone missing.");

  const snap = await db
    .collection("weddings")
    .doc(weddingId)
    .collection("rsvps")
    .where("phone", "==", p)
    .limit(1)
    .get();

  if (snap.empty) throw new HttpsError("permission-denied", "Not invited.");
  return { ok: true, rsvpDocId: snap.docs[0].id };
}


/**
 * -------------------------
 * Your existing WhatsApp callable
 * -------------------------
 */
exports.sendWeddingInvites = onCall(async (request) => {
  console.log("sendWeddingInvites called with data:", request.data);

  try {
    const { weddingId, eventId = null } = request.data || {};

    if (!weddingId || typeof weddingId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "weddingId is required",
      );
    }

    if (!WHATSAPP_TOKEN || !WHATSAPP_PHONE_ID) {
      console.error("WhatsApp env vars missing", {
        WHATSAPP_TOKEN_PRESENT: !!WHATSAPP_TOKEN,
        WHATSAPP_PHONE_ID_PRESENT: !!WHATSAPP_PHONE_ID,
      });
      throw new functions.https.HttpsError(
        "failed-precondition",
        "WhatsApp is not configured on the server.",
      );
    }

    const weddingRef = db.collection("weddings").doc(weddingId);
    const weddingSnap = await weddingRef.get();

    if (!weddingSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Wedding not found");
    }

    const wedding = weddingSnap.data() || {};
    const coupleName = wedding.coupleName || wedding.name || "our wedding";

    let guestIdsToTarget = null;
    if (eventId) {
      const eventGuestsSnap = await weddingRef
        .collection("events")
        .doc(eventId)
        .collection("eventGuests")
        .get();

      guestIdsToTarget = new Set();
      eventGuestsSnap.forEach((doc) => guestIdsToTarget.add(doc.id));
    }

    const guestsSnap = await weddingRef
      .collection("guests")
      .where("masterInviteSent", "==", false)
      .get();

    if (guestsSnap.empty) {
      console.log("No eligible guests found (masterInviteSent == false).");
      return { sent: 0, totalCandidates: 0 };
    }

    const batch = db.batch();
    let sentCount = 0;
    let candidateCount = 0;

    for (const doc of guestsSnap.docs) {
      const guestId = doc.id;

      if (guestIdsToTarget && !guestIdsToTarget.has(guestId)) continue;

      candidateCount++;

      const guest = doc.data() || {};
      const phone = (guest.phone || "").trim();
      const name = (guest.name || "there").trim();

      if (!phone) {
        console.log(`Skipping guest ${guestId}, no phone`);
        continue;
      }

      const payload = {
        messaging_product: "whatsapp",
        to: phone,
        type: "template",
        template: {
          name: "wedding_invite_v1",
          language: { code: "en" },
          components: [
            {
              type: "body",
              parameters: [
                { type: "text", text: name },       // {{1}}
                { type: "text", text: coupleName }, // {{2}}
                { type: "text", text: APP_LINK },   // {{3}}
              ],
            },
          ],
        },
      };

      try {
        console.log("Sending WhatsApp invite to:", phone);
        const res = await axios.post(
          `https://graph.facebook.com/v20.0/${WHATSAPP_PHONE_ID}/messages`,
          payload,
          {
            headers: {
              Authorization: `Bearer ${WHATSAPP_TOKEN}`,
              "Content-Type": "application/json",
            },
          },
        );

        console.log("WhatsApp API response:", res.data);

        batch.update(doc.ref, {
          masterInviteSent: true,
          masterInviteSentAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        sentCount++;
      } catch (err) {
        console.error(
          `❌ Failed to send invite to ${phone}`,
          err.response?.data || err.message || err.toString(),
        );
      }
    }

    if (sentCount > 0) {
      await batch.commit();
    }

    console.log("Invites summary:", { sentCount, candidateCount });
    return { sent: sentCount, totalCandidates: candidateCount };
  } catch (err) {
    console.error("sendWeddingInvites top-level error:", err);

    if (err instanceof functions.https.HttpsError) throw err;

    throw new functions.https.HttpsError(
      "internal",
      "Unexpected server error while sending invites.",
      err && err.toString(),
    );
  }
});

/**
 * -------------------------
 * ✅ Automated: Morning-of-event notifications
 * -------------------------
 *
 * - Runs every 5 minutes
 * - For each wedding, checks each event
 * - If today is the event day, and local time is within a window after 9:00 AM,
 *   sends reminder to RSVPs where eventResponses.<eventId> == "going"
 *
 * IMPORTANT:
 * - Event time field must be: event.dateTime = "2026-02-11T17:00:00+05:30"
 * - Optional: wedding.timeZone = "Asia/Dubai" (recommended)
 * - Avoid sending twice: event.morningNotified == true
 */
exports.sendMorningEventNotifications = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "UTC", // schedule tick is UTC, we compute local per wedding/event
  },
  async () => {
    console.log("⏰ sendMorningEventNotifications tick");

    const weddingsSnap = await db.collection("weddings").get();
    if (weddingsSnap.empty) return;

    for (const weddingDoc of weddingsSnap.docs) {
      const weddingId = weddingDoc.id;
      const wedding = weddingDoc.data() || {};
      const weddingTimeZone = wedding.timeZone || null;

      const eventsSnap = await db.collection("weddings").doc(weddingId).collection("events").get();
      if (eventsSnap.empty) continue;

      for (const eventDoc of eventsSnap.docs) {
        const eventId = eventDoc.id;
        const event = eventDoc.data() || {};

        // already sent?
        if (event.morningNotified === true) continue;

        const iso = event.dateTime; // ✅ your field
        if (!iso) continue;

        const eventStart = parseEventDateTime(iso);
        if (!eventStart) {
          console.log(`❌ Invalid event.dateTime for ${weddingId}/${eventId}:`, iso);
          continue;
        }

        // compute 9 AM local on same date
        const morningTime = computeMorningTrigger(eventStart, weddingTimeZone);

        // compute now in same zone used for morningTime
        const now = weddingTimeZone
          ? DateTime.now().setZone(weddingTimeZone)
          : DateTime.now().setZone(eventStart.zoneName);

        // Send window: 9:00 AM to 3:00 PM (6 hours window)
        const isDue = now >= morningTime && now <= morningTime.plus({ hours: 6 });
        if (!isDue) continue;

        console.log("✅ Morning reminder due:", {
          weddingId,
          eventId,
          now: now.toISO(),
          morningTime: morningTime.toISO(),
          zone: now.zoneName,
        });

        // Query RSVPs going for this event
        // rsvps: eventResponses.<eventId> == "going"
        const rsvpsSnap = await db
          .collection("weddings")
          .doc(weddingId)
          .collection("rsvps")
          .where(`eventResponses.${eventId}`, "==", "going")
          .get();

        const allTokens = [];
        for (const rsvpDoc of rsvpsSnap.docs) {
          const tokens = await getUserTokensByRsvp(weddingId, rsvpDoc.id);
          allTokens.push(...tokens);
        }

        const tokensUnique = Array.from(new Set(allTokens));

        // Send notification
        const title = event.title || event.name || "Event Reminder";
        const body = `Today: ${title}. Tap to see details.`;

        const result = await sendToTokens(tokensUnique, {
          notification: { title, body },
          data: {
            type: "EVENT_MORNING_REMINDER",
            weddingId: String(weddingId),
            eventId: String(eventId),
          },
        });

        console.log("📨 Morning push result:", result);

        // Mark as notified so it doesn't repeat
        await eventDoc.ref.update({
          morningNotified: true,
          morningNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          morningNotifiedCount: tokensUnique.length,
          morningNotifiedZone: now.zoneName,
        });
      }
    }
  }
);

/**
 * -------------------------
 * ✅ Debug callable: test instantly
 * -------------------------
 * data: { weddingId, eventId, title?, body? }
 */
exports.debugSendEventNotification = onCall(async (request) => {
  const { weddingId, eventId, title, body } = request.data || {};

  if (!weddingId || !eventId) {
    throw new HttpsError("invalid-argument", "weddingId and eventId are required");
  }

  const weddingRef = db.collection("weddings").doc(weddingId);
  const weddingSnap = await weddingRef.get();
  if (!weddingSnap.exists) throw new HttpsError("not-found", "Wedding not found");

  const eventRef = weddingRef.collection("events").doc(eventId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) throw new HttpsError("not-found", "Event not found");

  const event = eventSnap.data() || {};

  const rsvpsSnap = await weddingRef
    .collection("rsvps")
    .where(`eventResponses.${eventId}`, "==", "going")
    .get();

  const allTokens = [];
  for (const rsvpDoc of rsvpsSnap.docs) {
    const tokens = await getUserTokensByRsvp(weddingId, rsvpDoc.id);
    allTokens.push(...tokens);
  }

  const tokensUnique = Array.from(new Set(allTokens));

  const finalTitle = title || event.title || event.name || "Event Reminder";
  const finalBody = body || `Test push: ${finalTitle}`;

  const result = await sendToTokens(tokensUnique, {
    notification: { title: finalTitle, body: finalBody },
    data: {
      type: "EVENT_DEBUG",
      weddingId: String(weddingId),
      eventId: String(eventId),
    },
  });

  return {
    tokens: tokensUnique.length,
    result,
  };
});

exports.sendCustomEventNotification = onCall(async (request) => {
  const { weddingId, eventId, title, body } = request.data || {};

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  if (!weddingId || !eventId) {
    throw new HttpsError("invalid-argument", "weddingId and eventId are required.");
  }

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "title and body are required.");
  }

  // ---- Admin check (simple + safe) ----
  // Recommended: store adminUids in wedding doc:
  // weddings/{weddingId}.adminUids = ["uid1","uid2"]
  const weddingRef = db.collection("weddings").doc(weddingId);
  const weddingSnap = await weddingRef.get();
  if (!weddingSnap.exists) throw new HttpsError("not-found", "Wedding not found");

  const wedding = weddingSnap.data() || {};
  const adminUids = Array.isArray(wedding.adminUids) ? wedding.adminUids : [];
  const callerUid = request.auth.uid;

  // if (!adminUids.includes(callerUid)) {
  //   throw new HttpsError("permission-denied", "Only admins can send notifications.");
  // }

  // ---- Find RSVP'd users for this event ----
  const rsvpsSnap = await weddingRef
    .collection("rsvps")
    .where(`eventResponses.${eventId}`, "==", "going")
    .get();

  const allTokens = [];
  for (const rsvpDoc of rsvpsSnap.docs) {
    const tokens = await getUserTokensByRsvp(weddingId, rsvpDoc.id); // (your helper)
    allTokens.push(...tokens);
  }

  const tokensUnique = Array.from(new Set(allTokens));

  const result = await sendToTokens(tokensUnique, {
    notification: { title, body },
    data: {
      type: "EVENT_CUSTOM",
      weddingId: String(weddingId),
      eventId: String(eventId),
    },
  });

  return {
    targetedRsvps: rsvpsSnap.size,
    tokens: tokensUnique.length,
    result,
  };
});



// cloudfare

exports.createEventMediaUploadSessions = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const uid = request.auth.uid;
  const { weddingId, eventId, files } = request.data || {};

  if (!weddingId || !eventId || !Array.isArray(files) || files.length === 0) {
    throw new HttpsError("invalid-argument", "weddingId, eventId, files[] required.");
  }

  // phone from Firebase phone auth token
  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  if (files.length > 30) {
    throw new HttpsError("invalid-argument", "Max 30 files per batch.");
  }

  const sessions = [];

  for (const f of files) {
    const localId = f.localId;
    const mimeType = f.mimeType;
    const sizeBytes = Number(f.sizeBytes || 0);

    if (!localId || !mimeType || !sizeBytes) {
      throw new HttpsError("invalid-argument", "Each file needs localId, mimeType, sizeBytes.");
    }

    // limits (tune later)
    const isVideo = String(mimeType).toLowerCase().startsWith("video/");
    const maxBytes = isVideo ? 350 * 1024 * 1024 : 20 * 1024 * 1024;
    if (sizeBytes > maxBytes) {
      throw new HttpsError("invalid-argument", `File too large: ${f.name || localId}`);
    }

    const mediaId = uuidv4();
    const r2Key = buildR2Key({ weddingId, eventId, uid, mediaId, mimeType });

    const cmd = new PutObjectCommand({
      Bucket: R2_BUCKET,
      Key: r2Key,
      ContentType: mimeType,
      Metadata: {
        weddingId: String(weddingId),
        eventId: String(eventId),
        uid: String(uid),
      },
    });

    const uploadUrl = await getSignedUrl(r2, cmd, { expiresIn: 60 * 10 }); // 10 mins

    sessions.push({
      localId,
      mediaId,
      r2Key,
      uploadUrl,
      headers: { "Content-Type": mimeType },
    });
  }

  return { sessions };
});


exports.confirmEventMediaUpload = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const uid = request.auth.uid;
  const {
    weddingId,
    eventId,
    mediaId,
    r2Key,
    mimeType,
    sizeBytes,
    originalName,
    width,
    height,
    durationMs,
  } = request.data || {};

  if (!weddingId || !eventId || !mediaId || !r2Key || !mimeType) {
    throw new HttpsError("invalid-argument", "Missing weddingId/eventId/mediaId/r2Key/mimeType.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  const type = detectTypeFromMime(mimeType);

  // Optional: uploader name from users doc
  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.exists ? (userSnap.data() || {}) : {};
  const uploaderName = user.name || user.fullName || "";

  const mediaRef = db
    .collection("weddings")
    .doc(weddingId)
    .collection("events")
    .doc(eventId)
    .collection("media")
    .doc(mediaId);

  await mediaRef.set(
    {
      type,
      r2Key,
      mimeType,
      sizeBytes: Number(sizeBytes || 0),
      originalName: originalName || "",
      status: "ready",
      visibility: "eventGuestsOnly",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      uploadedBy: {
        uid,
        name: uploaderName,
        phone: normalizePhone(phone),
      },
      likeCount: 0,
      width: width ?? null,
      height: height ?? null,
      durationMs: durationMs ?? null,
    },
    { merge: true }
  );


  // ✅ 2) Create/Update mediaIndex pointer (NEW)
  const pointerId = `${eventId}_${mediaId}`;

  const mediaIndexRef = db
    .collection("weddings")
    .doc(weddingId)
    .collection("mediaIndex")
    .doc(pointerId);

  // If you want createdAt to match the media createdAt exactly,
  // you can read mediaRef after set, but that's extra read.
  // Using serverTimestamp is fine.
  await mediaIndexRef.set(
    {
      weddingId,
      eventId,
      mediaId,
      mediaPath: mediaRef.path,
      r2Key,
      type,
      mimeType,
      status: "ready",
      visibility: "eventGuestsOnly",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      uploadedByUid: uid,

      // ML pipeline
      indexStatus: type === "image" ? "pending" : "skipped",
      indexedAt: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }

  );

  // counters on event doc (recommended)
  const eventRef = db.collection("weddings").doc(weddingId).collection("events").doc(eventId);

  await db.runTransaction(async (tx) => {
    tx.set(
      eventRef,
      {
        mediaCount: admin.firestore.FieldValue.increment(1),
        photoCount: admin.firestore.FieldValue.increment(type === "image" ? 1 : 0),
        videoCount: admin.firestore.FieldValue.increment(type === "video" ? 1 : 0),
        lastMediaAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  return { ok: true };
});


exports.getEventMediaSignedUrls = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const { weddingId, eventId, items } = request.data || {};
  if (!weddingId || !eventId || !Array.isArray(items) || items.length === 0) {
    throw new HttpsError("invalid-argument", "weddingId, eventId, items[] required.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  if (items.length > 50) throw new HttpsError("invalid-argument", "Max 50 items per batch.");

  const urls = [];
  for (const it of items) {
    if (!it.mediaId || !it.r2Key) continue;

    const cmd = new GetObjectCommand({
      Bucket: R2_BUCKET,
      Key: it.r2Key,
      ResponseContentType: it.mimeType || undefined,
    });

    const url = await getSignedUrl(r2, cmd, { expiresIn: 60 * 60 * 3 }); // 3 hour
    urls.push({ mediaId: it.mediaId, url });
  }

  return { urls };
});


exports.getR2SignedUrls = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const { weddingId, items } = request.data || {};
  if (!weddingId || !Array.isArray(items) || items.length === 0) {
    throw new HttpsError("invalid-argument", "weddingId, items[] required.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  if (items.length > 50) {
    throw new HttpsError("invalid-argument", "Max 50 items per batch.");
  }

  const urls = [];
  for (const it of items) {
    const key = it?.key;
    if (!key) continue;

    const cmd = new GetObjectCommand({
      Bucket: R2_BUCKET,
      Key: key,
      ResponseContentType: it.mimeType || undefined,
    });

    const url = await getSignedUrl(r2, cmd, { expiresIn: 60 * 60 * 3 });
    urls.push({ key, url });
  }

  return { urls };
});


exports.deleteEventMedia = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const uid = request.auth.uid;
  const { weddingId, eventId, mediaId } = request.data || {};
  if (!weddingId || !eventId || !mediaId) {
    throw new HttpsError("invalid-argument", "weddingId, eventId, mediaId required.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  const mediaRef = db
    .collection("weddings")
    .doc(weddingId)
    .collection("events")
    .doc(eventId)
    .collection("media")
    .doc(mediaId);

  const snap = await mediaRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Media not found.");

  const media = snap.data() || {};
  const uploadedByUid = media.uploadedBy?.uid;
  const r2Key = media.r2Key;
  const mimeType = media.mimeType || "";
  const type = detectTypeFromMime(mimeType);

  // Host/admin check (based on your wedding doc adminUids pattern)
  const weddingSnap = await db.collection("weddings").doc(weddingId).get();
  const wedding = weddingSnap.exists ? (weddingSnap.data() || {}) : {};
  const adminUids = Array.isArray(wedding.adminUids) ? wedding.adminUids : [];
  const hostId = wedding.hostId || null;

  const canDelete = uploadedByUid === uid || hostId === uid || adminUids.includes(uid);
  if (!canDelete) throw new HttpsError("permission-denied", "You cannot delete this media.");

  // best-effort R2 delete
  if (r2Key) {
    try {
      await r2.send(new DeleteObjectCommand({ Bucket: R2_BUCKET, Key: r2Key }));
    } catch (e) {
      console.warn("R2 delete failed (continuing):", e?.message || e);
    }
  }

  await mediaRef.delete();

  // counters down
  const eventRef = db.collection("weddings").doc(weddingId).collection("events").doc(eventId);
  await db.runTransaction(async (tx) => {
    tx.set(
      eventRef,
      {
        mediaCount: admin.firestore.FieldValue.increment(-1),
        photoCount: admin.firestore.FieldValue.increment(type === "image" ? -1 : 0),
        videoCount: admin.firestore.FieldValue.increment(type === "video" ? -1 : 0),
      },
      { merge: true }
    );
  });

  return { ok: true };
});


// Backfill mediaIndex for a wedding in batches.
exports.backfillMediaIndex = onCall(
  {
    region: "asia-south1", // change to your region
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (request) => {
    const { weddingId, batchSize = 200, cursor } = request.data || {};
    const uid = request.auth?.uid;

    if (!uid) throw new HttpsError("unauthenticated", "Login required.");
    if (!weddingId) throw new HttpsError("invalid-argument", "weddingId required.");

    // OPTIONAL: admin check (recommended)
    // You can enforce that only admin users can run this.
    // Example: store admin UIDs in wedding doc, or use custom claims.
    // const weddingDoc = await db.collection("weddings").doc(weddingId).get();
    // if (!weddingDoc.exists) throw new HttpsError("not-found", "Wedding not found");
    // const admins = weddingDoc.data()?.admins || {};
    // if (!admins[uid]) throw new HttpsError("permission-denied", "Not an admin");

    const eventsRef = db.collection("weddings").doc(weddingId).collection("events");

    // We paginate by event doc order. Cursor is eventId of last processed event.
    let eventsQuery = eventsRef.orderBy(admin.firestore.FieldPath.documentId()).limit(25);
    if (cursor?.lastEventId) {
      eventsQuery = eventsRef
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAfter(cursor.lastEventId)
        .limit(25);
    }

    const eventsSnap = await eventsQuery.get();
    if (eventsSnap.empty) {
      return { done: true, processed: 0, nextCursor: null };
    }

    let processed = 0;
    let lastEventId = null;

    // Batch writes
    let batch = db.batch();
    let batchOps = 0;

    for (const eventDoc of eventsSnap.docs) {
      const eventId = eventDoc.id;
      lastEventId = eventId;

      // Read media docs in this event (limit to remaining capacity)
      const remaining = batchSize - processed;
      if (remaining <= 0) break;

      // If you want deeper pagination per event, add cursor.lastMediaIdByEvent[eventId].
      // For MVP (100 media), this simpler approach is enough.
      const mediaSnap = await eventsRef
        .doc(eventId)
        .collection("media")
        .where("status", "==", "ready")
        .where("type", "==", "image")
        .limit(remaining)
        .get();

      for (const mediaDoc of mediaSnap.docs) {
        const mediaId = mediaDoc.id;
        const data = mediaDoc.data() || {};

        const r2Key = data.r2Key;
        if (!r2Key) continue;

        const pointerId = `${eventId}_${mediaId}`;
        const pointerRef = db
          .collection("weddings")
          .doc(weddingId)
          .collection("mediaIndex")
          .doc(pointerId);

        batch.set(
          pointerRef,
          {
            weddingId,
            eventId,
            mediaId,
            mediaPath: mediaDoc.ref.path,
            r2Key: r2Key,
            type: data.type || "image",
            mimeType: data.mimeType || null,
            status: data.status || null,
            createdAt: data.createdAt || null,
            uploadedByUid: data.uploadedBy?.uid || null,
            visibility: data.visibility || null,

            // Worker can pick up from here
            indexStatus: "pending",
            indexedAt: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        processed++;
        batchOps++;

        // Firestore batch limit is 500 operations
        if (batchOps >= 450) {
          await batch.commit();
          batch = db.batch();
          batchOps = 0;
        }

        if (processed >= batchSize) break;
      }

      if (processed >= batchSize) break;
    }

    if (batchOps > 0) await batch.commit();

    // If we processed less than batchSize AND we hit end of eventsSnap,
    // caller can call again with cursor to continue.
    const nextCursor = { lastEventId };

    // Heuristic done flag: if fewer events returned than limit and processed < batchSize, likely done.
    const done = eventsSnap.size < 25 && processed < batchSize;

    return { done, processed, nextCursor };
  }
);


const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { GoogleAuth } = require("google-auth-library");

const ML_RUN_URL = process.env.ML_RUN_URL;
const auth = new GoogleAuth();

/**
 * Calls private Cloud Run with ID token
 */
async function callMlWorker(path, body) {
  if (!ML_RUN_URL) {
    console.error("Missing ML_RUN_URL env var");
    return;
  }

  const url = `${ML_RUN_URL}${path}`;

  const client = await auth.getIdTokenClient(url);

  await client.request({
    url,
    method: "POST",
    data: body,
    headers: { "Content-Type": "application/json" },
    timeout: 10 * 60 * 1000,
  });
}

// exports.onMediaIndexPending = onDocumentWritten(
//   {
//     document: "weddings/{weddingId}/mediaIndex/{pointerId}",
//     region: "us-central1",
//   },
//   async (event) => {
//     const after = event.data?.after?.data();
//     if (!after) return;

//     const before = event.data?.before?.data();

//     const beforeStatus = before?.indexStatus;
//     const afterStatus = after?.indexStatus;

//     // Only when status becomes pending
//     if (afterStatus !== "pending") return;
//     if (beforeStatus === "pending") return;

//     if (after.type !== "image") return;
//     if (after.status !== "ready") return;

//     const weddingId = event.params.weddingId;
//     const pointerId = event.params.pointerId;

//     console.log("Triggering ML worker for", weddingId, pointerId);

//     await callMlWorker("/indexMedia", { weddingId, pointerId });
//   }
// );

exports.onMediaIndexPending = onDocumentWritten(
  {
    document: "weddings/{weddingId}/mediaIndex/{pointerId}",
    region: "us-central1",
  },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) return;

    const before = event.data?.before?.data();

    if (after.indexStatus !== "pending") return;
    if (after.type !== "image") return;
    if (after.status !== "ready") return;

    const becamePending =
      (before?.indexStatus || null) !== "pending" && after.indexStatus === "pending";

    const beforeNonce = before?.kickNonce || null;
    const afterNonce = after?.kickNonce || null;
    const gotKicked = afterNonce && beforeNonce !== afterNonce;

    // ✅ only run when it *became* pending OR when kickNonce changed
    if (!becamePending && !gotKicked) return;

    const weddingId = event.params.weddingId;
    const pointerId = event.params.pointerId;

    console.log("Triggering ML worker for", weddingId, pointerId, {
      becamePending,
      gotKicked,
      afterNonce,
    });

    await callMlWorker("/indexMedia", { weddingId, pointerId });
  }
);

exports.kickIndexWeddingMedia = onCall(
  { region: "us-central1", timeoutSeconds: 120 },
  async (request) => {
    try {
      if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

      const { weddingId, limit } = request.data || {};
      if (!weddingId) throw new HttpsError("invalid-argument", "weddingId required.");

      const max = Math.min(Number(limit || 200), 1000);
      const uid = request.auth.uid;

      logger.info("kickIndexWeddingMedia called", { weddingId, uid, max });

      const weddingRef = db.collection("weddings").doc(weddingId);
      const weddingSnap = await weddingRef.get();
      if (!weddingSnap.exists) throw new HttpsError("not-found", "Wedding not found.");

      // Optional admin check (uncomment if you store admins map)
      // const wedding = weddingSnap.data() || {};
      // const admins = wedding.admins || {};
      // if (!admins[uid]) throw new HttpsError("permission-denied", "Only admins can run backfill.");

      const col = weddingRef.collection("mediaIndex");

      // ✅ No orderBy => avoids composite index requirement
      const q = col
        .where("indexStatus", "==", "pending")
        .where("type", "==", "image")
        .where("status", "==", "ready")
        .limit(max);

      const snap = await q.get();
      logger.info("Query result", { weddingId, size: snap.size });

      if (snap.empty) return { ok: true, kicked: 0 };

      const now = admin.firestore.FieldValue.serverTimestamp();
      const nonce = `${Date.now()}_${Math.random().toString(16).slice(2)}`;

      let kicked = 0;
      const docs = snap.docs;

      for (let i = 0; i < docs.length; i += 450) {
        const chunk = docs.slice(i, i + 450);
        const batch = db.batch();

        for (const d of chunk) {
          batch.update(d.ref, {
            kickAt: now,
            updatedAt: now,
            kickNonce: nonce,
          });
        }

        await batch.commit();
        kicked += chunk.length;

        logger.info("Kick batch committed", {
          weddingId,
          nonce,
          batchSize: chunk.length,
          kicked,
        });
      }

      logger.info("kickIndexWeddingMedia done", { weddingId, kicked, nonce });
      return { ok: true, kicked, nonce };
    } catch (err) {
      // Always convert to HttpsError so Flutter gets useful info
      logger.error("kickIndexWeddingMedia FAILED", { err: String(err), stack: err?.stack });

      if (err instanceof HttpsError) throw err;

      // Firestore index errors usually contain this phrase:
      const msg = String(err?.message || err);
      throw new HttpsError("internal", msg);
    }
  }
);




//user face enrollments . 

exports.createEnrollmentUploadSessions = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const uid = request.auth.uid;
  const { weddingId, files } = request.data || {};

  if (!weddingId || !Array.isArray(files) || files.length === 0) {
    throw new HttpsError("invalid-argument", "weddingId and files[] required.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  if (files.length > 5) {
    throw new HttpsError("invalid-argument", "Max 5 selfies allowed.");
  }

  const sessions = [];

  for (const f of files) {
    const { localId, mimeType, sizeBytes } = f;

    if (!localId || !mimeType || !sizeBytes) {
      throw new HttpsError("invalid-argument", "Each file needs localId, mimeType, sizeBytes.");
    }

    if (!mimeType.startsWith("image/")) {
      throw new HttpsError("invalid-argument", "Only images allowed for enrollment.");
    }

    const mediaId = uuidv4();

    const r2Key = `weddings/${weddingId}/enrollments/${uid}/${mediaId}.jpg`;

    const cmd = new PutObjectCommand({
      Bucket: R2_BUCKET,
      Key: r2Key,
      ContentType: mimeType,
      Metadata: {
        weddingId: String(weddingId),
        uid: String(uid),
        kind: "enrollment",
      },
    });

    const uploadUrl = await getSignedUrl(r2, cmd, { expiresIn: 60 * 10 });

    sessions.push({
      localId,
      mediaId,
      r2Key,
      uploadUrl,
      headers: { "Content-Type": mimeType },
    });
  }

  return { sessions };
});



exports.confirmEnrollmentUpload = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

  const uid = request.auth.uid;
  const { weddingId, mediaId, r2Key, mimeType, sizeBytes, originalName } = request.data || {};

  if (!weddingId || !mediaId || !r2Key || !mimeType) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const phone = request.auth.token?.phone_number;
  await assertInvitedByPhone(weddingId, phone);

  const enrollRef = db
    .collection("weddings")
    .doc(weddingId)
    .collection("enrollments")
    .doc(uid)
    .collection("media")
    .doc(mediaId);

  await enrollRef.set({
    type: "image",
    r2Key,
    mimeType,
    sizeBytes: Number(sizeBytes || 0),
    originalName: originalName || "",
    status: "ready",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),

    enrollStatus: "pending",
    processedAt: null,
  });

  return { ok: true };
});


exports.finalizeEnrollment = onCall(
  { region: "us-central1", timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required.");

    const uid = request.auth.uid;
    const { weddingId } = request.data || {};

    if (!weddingId) {
      throw new HttpsError("invalid-argument", "weddingId required.");
    }

    const enrollCol = db
      .collection("weddings")
      .doc(weddingId)
      .collection("enrollments")
      .doc(uid)
      .collection("media");

    const snap = await enrollCol.where("status", "==", "ready").get();

    if (snap.size < 3) {
      throw new HttpsError("failed-precondition", "Upload at least 3 selfies.");
    }

    // mark parent doc
    const parentRef = db
      .collection("weddings")
      .doc(weddingId)
      .collection("enrollments")
      .doc(uid);

    await parentRef.set(
      {
        enrollStatus: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // 🔥 call Cloud Run
    await callMlWorker("/enrollFromMedia", {
      weddingId,
      uid,
    });

    return { ok: true };
  }
);











