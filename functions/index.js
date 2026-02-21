const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createUserWithRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "No autenticado.",
    );
  }

  const callerUid = context.auth.uid;
  const caller = await admin.auth().getUser(callerUid);
  const callerRole =
        (caller.customClaims && caller.customClaims.role) || null;

  if (callerRole !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "No autorizado.",
    );
  }

  const email = (data.email || "").toString().trim().toLowerCase();
  const password = (data.password || "").toString();
  const role = (data.role || "").toString();

  const allowed = ["admin", "soporte_tecnico", "soporte_sistemas"];

  if (!email || !email.includes("@")) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Email inválido.",
    );
  }

  if (!password || password.length < 6) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Password mínimo 6.",
    );
  }

  if (!allowed.includes(role)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Rol inválido.",
    );
  }

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({email, password});
  } catch (e) {
    throw new functions.https.HttpsError("already-exists", String(e.message));
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, {role});

  await admin.firestore().doc(`users/${userRecord.uid}`).set(
      {
        uid: userRecord.uid,
        email,
        role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: callerUid,
        active: true,
      },
      {merge: true},
  );

  return {uid: userRecord.uid, email, role};
});
