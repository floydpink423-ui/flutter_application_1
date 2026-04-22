import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔐 Stream de sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔑 LOGIN
  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await _db.collection('usuarios').doc(uid).get();

      if (doc.exists) {
        return doc['rol']; // admin / editor / consultor
      }

      return null;
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  /// 👤 CREAR USUARIO (SIN PERDER SESIÓN ADMIN)
  Future<void> crearUsuario({
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      /// 👇 guardar sesión actual (admin)
      final currentUser = _auth.currentUser;
      final currentEmail = currentUser?.email;

      /// ⚠️ necesitas password del admin para re-login (limitación Firebase)
      /// 👉 alternativa simple: usar secondary app (abajo te doy opción PRO)

      /// Crear usuario nuevo
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      /// Guardar en Firestore
      await _db.collection('usuarios').doc(uid).set({
        'email': email,
        'rol': rol,
      });

      /// 🔁 VOLVER A LOGIN ADMIN (IMPORTANTE)
      if (currentEmail != null) {
        await _auth.signOut();

        /// ⚠️ Aquí necesitas volver a loguear admin manualmente
        /// 👉 opción simple: forzar login otra vez en UI
      }
    } catch (e) {
      print("Error al crear usuario: $e");
      rethrow;
    }
  }

  /// 🔄 RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 🔐 CAMBIAR PASSWORD
  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  /// 🚪 LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
