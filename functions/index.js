const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const { getFirestore } = require("firebase-admin/firestore");

admin.initializeApp();

const DB_ID = "crm-solucionesti"; // 👈 TU databaseId (el que se ve en el selector)
const db = getFirestore(admin.app(), DB_ID);

const corsHandler = cors({
  origin: true,
  methods: ["POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
});

exports.createUserWithRoleHttp = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }

    try {
      if (req.method !== "POST") {
        return res.status(405).json({
          error: { message: "Method not allowed", status: "METHOD_NOT_ALLOWED" },
        });
      }

      const authHeader = req.headers.authorization || "";
      const match = authHeader.match(/^Bearer (.+)$/);

      if (!match) {
        return res.status(401).json({
          error: {
            message: "No autenticado (missing Bearer token)",
            status: "UNAUTHENTICATED",
          },
        });
      }

      const idToken = match[1];

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        console.error("verifyIdToken failed:", e);
        return res.status(401).json({
          error: {
            message: `Token inválido o expirado: ${String(e.message || e)}`,
            status: "UNAUTHENTICATED",
          },
        });
      }

      const callerUid = decoded.uid;
      const callerRole = decoded.role || null;

      if (callerRole !== "admin") {
        return res.status(403).json({
          error: {
            message: "No autorizado (se requiere admin)",
            status: "PERMISSION_DENIED",
          },
        });
      }

      const body = req.body || {};
      const data = body.data || body;

      const email = (data.email || "").toString().trim().toLowerCase();
      const password = (data.password || "").toString();
      const role = (data.role || "").toString();
      const firstName = (data.firstName || "").toString().trim();
      const lastName = (data.lastName || "").toString().trim();
      const photoURL = (data.photoURL || "").toString().trim();

      // Validación dinámica de roles
      const roleDoc = await db.collection("roles").doc(role).get();
      if (!roleDoc.exists) {
        return res.status(400).json({
          error: { message: `Rol '${role}' no existe`, status: "INVALID_ARGUMENT" },
        });
      }

      if (!email || !email.includes("@")) {
        return res.status(400).json({
          error: { message: "Email inválido", status: "INVALID_ARGUMENT" },
        });
      }

      if (!password || password.length < 6) {
        return res.status(400).json({
          error: { message: "Password mínimo 6", status: "INVALID_ARGUMENT" },
        });
      }

      if (!password || password.length < 6) {
        return res.status(400).json({
          error: { message: "Password mínimo 6", status: "INVALID_ARGUMENT" },
        });
      }

      let userRecord;
      try {
        userRecord = await admin.auth().createUser({ email, password });
      } catch (e) {
        console.error("createUser failed:", e);
        return res.status(409).json({
          error: { message: String(e.message || e), status: "ALREADY_EXISTS" },
        });
      }

      await admin.auth().setCustomUserClaims(userRecord.uid, { role });

      // Actualizar perfil de Auth si hay datos
      if (firstName || photoURL) {
        await admin.auth().updateUser(userRecord.uid, {
          displayName: `${firstName} ${lastName}`.trim() || undefined,
          photoURL: photoURL || undefined,
        });
      }

      // ✅ Usamos "db" (databaseId crm-solucionesti)
      await db.doc(`users/${userRecord.uid}`).set(
        {
          uid: userRecord.uid,
          email,
          role,
          firstName,
          lastName,
          photoURL,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: callerUid,
          active: true,
        },
        { merge: true },
      );

      return res.status(200).json({
        uid: userRecord.uid,
        email,
        role,
      });
    } catch (e) {
      console.error("createUserWithRoleHttp unexpected error:", e);
      return res.status(500).json({
        error: {
          message: `Internal error: ${String(e.message || e)}`,
          status: "INTERNAL",
        },
      });
    }
  });
});

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// ✅ Notificar cuando se acerca la fecha límite (ejecutar cada hora)
exports.checkDueSoonActivities = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const fourHoursFromNow = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 4 * 60 * 60 * 1000)
    );

    // Buscar actividades que vencen en las próximas 4 horas
    const snapshot = await db
      .collection('oper_activities')
      .where('plannedEndAt', '>=', now)
      .where('plannedEndAt', '<=', fourHoursFromNow)
      .where('status', 'in', ['planned', 'in_progress'])
      .get();

    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const activity = doc.data();

      for (const uid of activity.assigneesUids) {
        const notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          type: 'activityDueSoon',
          title: '⏰ Actividad por vencer',
          body: `La actividad "${activity.title}" vence pronto`,
          activityId: doc.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: 'system',
          senderEmail: 'sistema@crm.com',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    console.log(`Notificaciones enviadas para ${snapshot.docs.length} actividades`);
  });

// ✅ Verificar SLA breached (ejecutar cada 30 minutos)
exports.checkSlaBreached = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const snapshot = await db
      .collection('oper_activities')
      .where('slaDeadline', '<=', now)
      .where('slaBreached', '==', false)
      .where('status', 'in', ['planned', 'in_progress'])
      .get();

    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const activity = doc.data();

      // Marcar SLA como incumplido
      batch.update(doc.ref, {
        slaBreached: true,
        slaBreachedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Crear notificación
      for (const uid of activity.assigneesUids) {
        const notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          type: 'slaBreached',
          title: '🚨 SLA Incumplido',
          body: `El SLA de "${activity.title}" ha sido incumplido`,
          activityId: doc.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: 'system',
          senderEmail: 'sistema@crm.com',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Log
      const logRef = doc.ref.collection('logs').doc();
      batch.set(logRef, {
        action: 'slaBreached',
        description: `SLA de ${activity.slaHours}h incumplido`,
        performedByUid: 'system',
        performedByEmail: 'sistema@crm.com',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`SLA verificado: ${snapshot.docs.length} incumplidos`);
  });