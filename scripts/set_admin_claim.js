/**
 * Asigna el custom claim role=admin a un UID.
 * Requiere una Service Account Key JSON (solo local, NO subir al repo).
 */
const admin = require('firebase-admin');
const path = require('path');

// Cambia el nombre del archivo si lo guardas distinto
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

async function main() {
    const uid = 'BZWEgCov5FOvnwFGwcSIXnnVttz2';

    await admin.auth().setCustomUserClaims(uid, { role: 'admin' });

    console.log(`✅ Claim asignado: ${uid} -> role=admin`);
    process.exit(0);
}

main().catch((e) => {
    console.error('❌ Error asignando claim:', e);
    process.exit(1);
});