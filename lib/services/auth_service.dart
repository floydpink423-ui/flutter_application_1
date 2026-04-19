import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔥 CREAR USUARIO BIEN HECHO
  Future<void> crearUsuario({
    required String email,
    required String password,
    required String rol,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('usuarios').doc(uid).set({
      "email": email,
      "rol": rol,
    });
  }

  Future<String> getRol(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();

    if (!doc.exists) return "consultor";

    return doc.data()?['rol'] ?? "consultor";
  }
}
