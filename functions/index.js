const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const {getFirestore} = require("firebase-admin/firestore");

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
          error: {message: "Method not allowed", status: "METHOD_NOT_ALLOWED"},
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

      const allowed = ["admin", "soporte_tecnico", "soporte_sistemas"];

      if (!email || !email.includes("@")) {
        return res.status(400).json({
          error: {message: "Email inválido", status: "INVALID_ARGUMENT"},
        });
      }

      if (!password || password.length < 6) {
        return res.status(400).json({
          error: {message: "Password mínimo 6", status: "INVALID_ARGUMENT"},
        });
      }

      if (!allowed.includes(role)) {
        return res.status(400).json({
          error: {message: "Rol inválido", status: "INVALID_ARGUMENT"},
        });
      }

      let userRecord;
      try {
        userRecord = await admin.auth().createUser({email, password});
      } catch (e) {
        console.error("createUser failed:", e);
        return res.status(409).json({
          error: {message: String(e.message || e), status: "ALREADY_EXISTS"},
        });
      }

      await admin.auth().setCustomUserClaims(userRecord.uid, {role});

      // ✅ AQUÍ está el cambio importante: usamos "db" (databaseId crm-solucionesti)
      await db.doc(`users/${userRecord.uid}`).set(
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
