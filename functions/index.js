
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

admin.initializeApp();
const db = admin.firestore();

// Read from .env
const WHATSAPP_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const WHATSAPP_PHONE_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const APP_LINK = process.env.WHATSAPP_APP_LINK || "https://yourapp.com/download";

/**
 * Callable function:
 * Sends WhatsApp wedding invites to all guests of a wedding
 * whose `masterInviteSent == false`.
 *
 * Optionally, if `eventId` is passed, only sends to guests
 * that are part of that event.
 *
 * data: { weddingId: string, eventId?: string }
 */
exports.sendWeddingInvites = onCall(async (request) => {
  console.log("sendWeddingInvites called with data:", request.data);

  try {
    // ✅ context is now defined
    // if (!context.auth) {
    //   throw new functions.https.HttpsError(
    //     "unauthenticated",
    //     "You must be logged in to send invites.",
    //   );
    // }

    // const weddingId = data?.weddingId;
    // const eventId = data?.eventId ?? null;

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
    const coupleName = wedding.coupleName || "our wedding";

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

      if (guestIdsToTarget && !guestIdsToTarget.has(guestId)) {
        continue;
      }

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

    if (err instanceof functions.https.HttpsError) {
      throw err;
    }

    throw new functions.https.HttpsError(
      "internal",
      "Unexpected server error while sending invites.",
      err && err.toString(),
    );
  }
});

