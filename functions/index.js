"use strict";

const functions = require("firebase-functions"); // for HttpsError fallback usage
const admin = require("firebase-admin");
const axios = require("axios");

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { DateTime } = require("luxon");

admin.initializeApp();
const db = admin.firestore();

// Read from .env
const WHATSAPP_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const WHATSAPP_PHONE_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const APP_LINK = process.env.WHATSAPP_APP_LINK || "https://yourapp.com/download";

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

