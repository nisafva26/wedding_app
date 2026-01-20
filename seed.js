
// seed.js
const admin = require("firebase-admin");
const path = require("path");

// Load service account key
const serviceAccount = require(path.join(__dirname, "serviceAccountKey.json"));

// Initialize Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

async function main() {
  console.log("🚀 Starting seed...");

  // ------------------------------
  // 1) Create or fetch Admin User
  // ------------------------------
  const adminEmail = "admin@example.com";  // change later

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(adminEmail);
    console.log("Admin already exists:", userRecord.uid);
  } catch (e) {
    userRecord = await auth.createUser({
      email: adminEmail,
      password: "Temp#12345",
      displayName: "Wedding Admin",
    });
    console.log("Created Admin:", userRecord.uid);
  }

  const adminUid = userRecord.uid;

  // ---------------------------------
  // 2) Create Wedding Project
  // ---------------------------------
  const weddingRef = db.collection("weddings").doc();
  const weddingId = weddingRef.id;

  await weddingRef.set({
    name: "Sample Wedding",
    dateRange: { start: "2026-01-10", end: "2026-01-12" },
    admins: [adminUid],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("Created wedding:", weddingId);

  // ---------------------------------
  // 3) Create Sub Events
  // ---------------------------------
  const events = [
    { name: "Haldi", date: "2026-01-10", time: "10:00 AM", venue: "Home", dressCode: "Yellow" },
    { name: "Mehendi", date: "2026-01-10", time: "06:00 PM", venue: "Hall A", dressCode: "Green" },
    { name: "Wedding", date: "2026-01-11", time: "04:00 PM", venue: "Convention Centre", dressCode: "Traditional" },
    { name: "Reception", date: "2026-01-12", time: "07:00 PM", venue: "Grand Ballroom", dressCode: "Formal" },
  ];

  const eventIds = {};

  for (const ev of events) {
    const evRef = weddingRef.collection("events").doc();
    await evRef.set({
      ...ev,
      status: "upcoming",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    eventIds[ev.name] = evRef.id;
    console.log("Created event:", ev.name, evRef.id);
  }

  // ---------------------------------
  // 4) Create Master Guest List
  // ---------------------------------
  const guests = [
    {
      name: "Arjun Menon",
      phone: "+919876543210",
      invited: ["Haldi", "Wedding", "Reception"],
    },
    {
      name: "Sara Thomas",
      phone: "+919812345678",
      invited: ["Mehendi", "Wedding"],
    },
    {
      name: "Family Group",
      phone: "+911234567890",
      invited: ["Haldi", "Mehendi", "Wedding", "Reception"],
    },
  ];

  for (const g of guests) {
    const gRef = weddingRef.collection("guests").doc();
    const invitedEventIds = g.invited.map((name) => eventIds[name]);

    // Create guest document
    await gRef.set({
      name: g.name,
      phone: g.phone,
      invitedEventIds,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Added guest:", g.name, gRef.id);

    // Link guest to each invited event
    for (const eventName of g.invited) {
      const evId = eventIds[eventName];
      const egRef = weddingRef
        .collection("events")
        .doc(evId)
        .collection("eventGuests")
        .doc(gRef.id);

      await egRef.set({
        guestId: gRef.id,
        status: "invited",
      });

      console.log(`Linked ${g.name} → ${eventName}`);
    }
  }

  // ---------------------------------
  // 5) Create User Profile
  // ---------------------------------
  await db.collection("users").doc(adminUid).set(
    {
      displayName: "Wedding Admin",
      email: adminEmail,
      role: "admin",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  console.log("Seed completed successfully 🎉");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Seed failed:", err);
    process.exit(1);
  });
