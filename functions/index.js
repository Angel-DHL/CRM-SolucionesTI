const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const nodemailer = require("nodemailer");
const { getFirestore } = require("firebase-admin/firestore");

admin.initializeApp();

const DB_ID = "crm-solucionesti";
const db = getFirestore(admin.app(), DB_ID);

const corsHandler = cors({
  origin: true,
  methods: ["POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
});

// ═════════════════════════════════════════════════════════════
// GESTIÓN DE ROLES Y USUARIOS
// ═════════════════════════════════════════════════════════════

/**
 * Actualiza el rol de un usuario tanto en Auth (Custom Claims) como en Firestore.
 * Solo puede ser ejecutada por un Administrador.
 */
exports.setUserRole = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const authHeader = req.headers.authorization || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      return res.status(401).json({ error: "No autorizado (falta token)" });
    }

    const idToken = match[1];

    try {
      // 1. Verificar que el que llama es un Admin
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      if (decodedToken.role !== "admin") {
        return res.status(403).json({ error: "Permisos insuficientes. Se requiere ser Administrador." });
      }

      const body = req.body || {};
      const data = body.data || body;
      const { uid, role } = data;

      if (!uid || !role) {
        return res.status(400).json({ error: "Faltan parámetros: uid y role son requeridos." });
      }

      // 2. Actualizar Custom Claims en Firebase Auth
      await admin.auth().setCustomUserClaims(uid, { role: role });

      // 3. Actualizar documento en Firestore
      await db.collection("users").doc(uid).update({
        role: role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Rol actualizado para usuario ${uid}: ${role}`);
      return res.status(200).json({ success: true, message: `Rol actualizado a ${role}` });
    } catch (error) {
      console.error("Error al actualizar rol:", error);
      return res.status(500).json({ error: error.message });
    }
  });
});

// ═════════════════════════════════════════════════════════════
// CONFIGURACIÓN SMTP (Gmail con App Password)
// ═════════════════════════════════════════════════════════════
// Las credenciales se leen del archivo functions/.env
// SMTP_EMAIL=ventasmarketingsti@gmail.com
// SMTP_PASSWORD=yffn hbah qvya rguu

function getTransporter() {
  const email = process.env.SMTP_EMAIL || "";
  const password = process.env.SMTP_PASSWORD || "";

  if (!email || !password) {
    console.error("SMTP no configurado. Agrega SMTP_EMAIL y SMTP_PASSWORD al archivo functions/.env");
    return null;
  }

  // Detectar si es Gmail o un SMTP personalizado
  const isGmail = email.includes("gmail.com");

  return nodemailer.createTransport({
    host: isGmail ? "smtp.gmail.com" : "mail.solucionesti.com.mx",
    port: 465,
    secure: true,
    auth: { user: email, pass: password },
  });
}

// ═════════════════════════════════════════════════════════════
// CREAR USUARIO CON ROL
// ═════════════════════════════════════════════════════════════

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
          error: { message: "No autenticado (missing Bearer token)", status: "UNAUTHENTICATED" },
        });
      }

      const idToken = match[1];

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        console.error("verifyIdToken failed:", e);
        return res.status(401).json({
          error: { message: `Token inválido o expirado: ${String(e.message || e)}`, status: "UNAUTHENTICATED" },
        });
      }

      const callerUid = decoded.uid;
      const callerRole = decoded.role || null;

      if (callerRole !== "admin") {
        return res.status(403).json({
          error: { message: "No autorizado (se requiere admin)", status: "PERMISSION_DENIED" },
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

      if (firstName || photoURL) {
        await admin.auth().updateUser(userRecord.uid, {
          displayName: `${firstName} ${lastName}`.trim() || undefined,
          photoURL: photoURL || undefined,
        });
      }

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

      return res.status(200).json({ uid: userRecord.uid, email, role });
    } catch (e) {
      console.error("createUserWithRoleHttp unexpected error:", e);
      return res.status(500).json({
        error: { message: `Internal error: ${String(e.message || e)}`, status: "INTERNAL" },
      });
    }
  });
});

// ═════════════════════════════════════════════════════════════
// ENVIAR COTIZACIÓN POR EMAIL
// ═════════════════════════════════════════════════════════════

exports.sendQuoteEmail = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method === "OPTIONS") return res.status(204).send("");

    try {
      if (req.method !== "POST") {
        return res.status(405).json({ error: "Method not allowed" });
      }

      // Verificar autenticación
      const authHeader = req.headers.authorization || "";
      const tokenMatch = authHeader.match(/^Bearer (.+)$/);
      if (!tokenMatch) {
        return res.status(401).json({ error: "No autenticado" });
      }

      try {
        await admin.auth().verifyIdToken(tokenMatch[1]);
      } catch (e) {
        return res.status(401).json({ error: "Token inválido" });
      }

      const body = req.body || {};
      const data = body.data || body;

      const { quoteId, toEmail, toName, pdfBase64 } = data;

      if (!quoteId || !toEmail) {
        return res.status(400).json({ error: "quoteId y toEmail son requeridos" });
      }

      // Obtener datos de la cotización
      const quoteSnap = await db.collection("sales_quotes").doc(quoteId).get();
      if (!quoteSnap.exists) {
        return res.status(404).json({ error: "Cotización no encontrada" });
      }

      const quote = quoteSnap.data();
      const folio = quote.folio || "SIN-FOLIO";
      const total = (quote.total || 0).toFixed(2);
      const moneda = quote.moneda || "MXN";

      // Verificar SMTP
      const transporter = getTransporter();
      if (!transporter) {
        return res.status(500).json({
          error: "SMTP no configurado. Ejecuta: firebase functions:config:set smtp.email=XX smtp.password=XX",
        });
      }

      // Construir email HTML profesional
      const htmlBody = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0; padding:0; background:#f5f5f5; font-family: 'Segoe UI', Arial, sans-serif;">
  <div style="max-width:600px; margin:20px auto; background:#ffffff; border-radius:12px; overflow:hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08);">
    
    <!-- Header -->
    <div style="background:#44562C; padding:24px 32px;">
      <h1 style="color:#ACC952; margin:0; font-size:22px;">Soluciones TI</h1>
      <p style="color:#C8D1BC; margin:4px 0 0; font-size:12px;">Tecnología e Innovación</p>
    </div>

    <!-- Content -->
    <div style="padding:32px;">
      <p style="color:#333; font-size:15px; margin:0 0 8px;">Estimado/a <strong>${toName || "Cliente"}</strong>,</p>
      <p style="color:#555; font-size:14px; line-height:1.6; margin:0 0 24px;">
        Le hacemos llegar nuestra cotización <strong>${folio}</strong> para su consideración.
        Adjunto encontrará el documento en formato PDF con el detalle completo.
      </p>

      <!-- Quote summary box -->
      <div style="background:#F0F5E4; border-left:4px solid #44562C; padding:16px 20px; border-radius:0 8px 8px 0; margin:0 0 24px;">
        <table style="width:100%; border:none;">
          <tr>
            <td style="color:#666; font-size:13px; padding:4px 0;">Folio:</td>
            <td style="color:#333; font-size:13px; font-weight:bold; text-align:right;">${folio}</td>
          </tr>
          <tr>
            <td style="color:#666; font-size:13px; padding:4px 0;">Total:</td>
            <td style="color:#44562C; font-size:16px; font-weight:bold; text-align:right;">$${total} ${moneda}</td>
          </tr>
          <tr>
            <td style="color:#666; font-size:13px; padding:4px 0;">Vigencia:</td>
            <td style="color:#333; font-size:13px; text-align:right;">${quote.vigenciaDias || 15} días</td>
          </tr>
        </table>
      </div>

      <p style="color:#555; font-size:14px; line-height:1.6; margin:0 0 8px;">
        Quedamos a sus órdenes para cualquier duda o aclaración.
      </p>
      <p style="color:#555; font-size:14px; margin:0;">Saludos cordiales,</p>
      <p style="color:#44562C; font-size:14px; font-weight:bold; margin:8px 0 0;">Equipo de Ventas — Soluciones TI</p>
    </div>

    <!-- Footer -->
    <div style="background:#f9f9f9; padding:16px 32px; border-top:1px solid #eee;">
      <p style="color:#999; font-size:11px; margin:0;">
        📍 Fuente de Ebro 301 A, Col. Las Fuentes &nbsp;|&nbsp; 📞 442 807 0229 &nbsp;|&nbsp; ✉️ ventas@solucionesti.com.mx
      </p>
    </div>
  </div>
</body>
</html>`;

      // Preparar adjunto PDF (si se envía base64)
      const attachments = [];
      if (pdfBase64) {
        attachments.push({
          filename: `${folio}.pdf`,
          content: Buffer.from(pdfBase64, "base64"),
          contentType: "application/pdf",
        });
      }

      // Enviar email
      await transporter.sendMail({
        from: `"Soluciones TI - Ventas" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject: `Cotización ${folio} — Soluciones TI ($${total} ${moneda})`,
        html: htmlBody,
        attachments,
      });

      // Actualizar cotización en Firestore
      await db.collection("sales_quotes").doc(quoteId).update({
        emailEnviadoAt: admin.firestore.FieldValue.serverTimestamp(),
        emailEnviadoA: toEmail,
        status: quote.status === "borrador" ? "enviada" : quote.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Cotización ${folio} enviada a ${toEmail}`);
      return res.status(200).json({ success: true, message: `Cotización enviada a ${toEmail}` });
    } catch (e) {
      console.error("sendQuoteEmail error:", e);
      return res.status(500).json({ error: `Error enviando email: ${String(e.message || e)}` });
    }
  });
});

// ═════════════════════════════════════════════════════════════
// CRON: VERIFICAR ACTIVIDADES POR VENCER (API v2)
// ═════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.checkDueSoonActivities = onSchedule("every 1 hours", async () => {
  const now = admin.firestore.Timestamp.now();
  const fourHoursFromNow = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 4 * 60 * 60 * 1000),
  );

  const snapshot = await db
    .collection("oper_activities")
    .where("plannedEndAt", ">=", now)
    .where("plannedEndAt", "<=", fourHoursFromNow)
    .where("status", "in", ["planned", "in_progress"])
    .get();

  const batch = db.batch();

  for (const doc of snapshot.docs) {
    const activity = doc.data();

    for (const uid of activity.assigneesUids) {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        type: "activityDueSoon",
        title: "⏰ Actividad por vencer",
        body: `La actividad "${activity.title}" vence pronto`,
        activityId: doc.id,
        activityTitle: activity.title,
        recipientUid: uid,
        senderUid: "system",
        senderEmail: "sistema@crm.com",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  await batch.commit();
  console.log(`Notificaciones enviadas para ${snapshot.docs.length} actividades`);
});

// ═════════════════════════════════════════════════════════════
// CRON: VERIFICAR SLA INCUMPLIDO (API v2)
// ═════════════════════════════════════════════════════════════

exports.checkSlaBreached = onSchedule("every 30 minutes", async () => {
  const now = admin.firestore.Timestamp.now();

  const snapshot = await db
    .collection("oper_activities")
    .where("slaDeadline", "<=", now)
    .where("slaBreached", "==", false)
    .where("status", "in", ["planned", "in_progress"])
    .get();

  const batch = db.batch();

  for (const doc of snapshot.docs) {
    const activity = doc.data();

    batch.update(doc.ref, {
      slaBreached: true,
      slaBreachedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    for (const uid of activity.assigneesUids) {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        type: "slaBreached",
        title: "🚨 SLA Incumplido",
        body: `El SLA de "${activity.title}" ha sido incumplido`,
        activityId: doc.id,
        activityTitle: activity.title,
        recipientUid: uid,
        senderUid: "system",
        senderEmail: "sistema@crm.com",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const logRef = doc.ref.collection("logs").doc();
    batch.set(logRef, {
      action: "slaBreached",
      description: `SLA de ${activity.slaHours}h incumplido`,
      performedByUid: "system",
      performedByEmail: "sistema@crm.com",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`SLA verificado: ${snapshot.docs.length} incumplidos`);
});

// ═════════════════════════════════════════════════════════════
// YOUTUBE DATA API v3 — Proxy para métricas del canal
// ═════════════════════════════════════════════════════════════

exports.fetchYouTubeMetrics = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    // Verificar autenticación
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!idToken) {
      return res.status(401).json({ error: "No autorizado" });
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      return res.status(401).json({ error: "Token inválido" });
    }

    const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || "";
    const YOUTUBE_CHANNEL_ID = process.env.YOUTUBE_CHANNEL_ID || "";

    if (!YOUTUBE_API_KEY) {
      return res.status(500).json({ error: "YOUTUBE_API_KEY no configurada en .env" });
    }

    try {
      // 1) Obtener estadísticas del canal
      let channelUrl = `https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&key=${YOUTUBE_API_KEY}`;
      if (YOUTUBE_CHANNEL_ID) {
        channelUrl += `&id=${YOUTUBE_CHANNEL_ID}`;
      } else {
        channelUrl += `&mine=true`;
      }

      const channelRes = await fetch(channelUrl);
      const channelData = await channelRes.json();

      if (!channelData.items || channelData.items.length === 0) {
        return res.status(404).json({ error: "Canal no encontrado. Configura YOUTUBE_CHANNEL_ID en .env" });
      }

      const channel = channelData.items[0];
      const stats = channel.statistics;
      const snippet = channel.snippet;

      // 2) Obtener últimos videos para métricas de engagement
      const videosUrl = `https://www.googleapis.com/youtube/v3/search?part=id&channelId=${channel.id}&type=video&order=date&maxResults=10&key=${YOUTUBE_API_KEY}`;
      const videosRes = await fetch(videosUrl);
      const videosData = await videosRes.json();

      let totalLikes = 0;
      let totalComments = 0;
      let totalViews = 0;
      let bestVideoTitle = "";
      let bestVideoViews = 0;
      let bestVideoId = "";

      if (videosData.items && videosData.items.length > 0) {
        const videoIds = videosData.items.map((v) => v.id.videoId).join(",");
        const statsUrl = `https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet&id=${videoIds}&key=${YOUTUBE_API_KEY}`;
        const statsRes = await fetch(statsUrl);
        const statsData = await statsRes.json();

        for (const video of (statsData.items || [])) {
          const vs = video.statistics;
          const views = parseInt(vs.viewCount || "0");
          totalLikes += parseInt(vs.likeCount || "0");
          totalComments += parseInt(vs.commentCount || "0");
          totalViews += views;

          if (views > bestVideoViews) {
            bestVideoViews = views;
            bestVideoTitle = video.snippet.title;
            bestVideoId = video.id;
          }
        }
      }

      // 3) Guardar en Firestore
      const now = new Date();
      const metricData = {
        plataforma: "youtube",
        fecha: admin.firestore.Timestamp.fromDate(now),
        periodo: "mensual",
        seguidores: 0,
        nuevosSeguidores: 0,
        publicaciones: parseInt(stats.videoCount || "0"),
        alcance: parseInt(stats.viewCount || "0"),
        impresiones: parseInt(stats.viewCount || "0"),
        engagement: 0,
        clics: 0,
        compartidos: 0,
        comentarios: totalComments,
        likes: totalLikes,
        vistas: totalViews,
        suscriptores: parseInt(stats.subscriberCount || "0"),
        duracionPromedio: 0,
        usuarios: 0,
        sesiones: 0,
        bounceRate: 0,
        duracionSesion: 0,
        conversiones: 0,
        mejorContenidoTitulo: bestVideoTitle || null,
        mejorContenidoUrl: bestVideoId ? `https://youtube.com/watch?v=${bestVideoId}` : null,
        mejorContenidoMetrica: bestVideoViews,
        datosExtra: {
          channelTitle: snippet.title,
          totalSubscribers: stats.subscriberCount,
          totalViews: stats.viewCount,
          totalVideos: stats.videoCount,
        },
        fuenteDatos: "api",
        createdAt: admin.firestore.Timestamp.fromDate(now),
      };

      await db.collection("marketing_social_metrics").add(metricData);

      return res.status(200).json({
        success: true,
        channel: snippet.title,
        subscribers: stats.subscriberCount,
        totalViews: stats.viewCount,
        totalVideos: stats.videoCount,
        recentLikes: totalLikes,
        recentComments: totalComments,
        bestVideo: bestVideoTitle,
      });
    } catch (error) {
      console.error("YouTube API error:", error);
      return res.status(500).json({ error: error.message });
    }
  });
});