const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/// 🔐 RESET PASSWORD POR ADMIN
exports.resetPasswordByAdmin = functions.https.onCall(async (data, context) => {

  // ❌ No autenticado
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "No autenticado"
    );
  }

  const adminUid = context.auth.uid;

  // 🔍 Verificar rol en Firestore
  const adminDoc = await admin.firestore()
    .collection("usuarios")
    .doc(adminUid)
    .get();

  const rol = adminDoc.data()?.rol;

  if (rol !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "No autorizado"
    );
  }

  const targetUid = data.uid;

  if (!targetUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "UID requerido"
    );
  }

  // 🔑 Generar contraseña temporal
  const tempPassword = Math.random().toString(36).slice(-8);

  // 🔄 Actualizar en Firebase Auth
  await admin.auth().updateUser(targetUid, {
    password: tempPassword,
  });

  // 🔐 (OPCIONAL) Marcar en Firestore
  await admin.firestore()
    .collection("usuarios")
    .doc(targetUid)
    .update({
      mustChangePassword: true,
    });

  return {
    ok: true,
    password: tempPassword,
  };
});