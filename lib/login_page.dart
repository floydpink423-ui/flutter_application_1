import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String error = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginGuardado();
  }

  /// 🔍 VERIFICA SI YA HAY USUARIO GUARDADO
  Future<void> _checkLoginGuardado() async {
    final user = FirebaseAuth.instance.currentUser;

    // 🔴 Si Firebase ya NO tiene sesión → NO redirigir
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .get();

      final rol = doc.data()?["rol"] ?? "consultor";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(rol: rol)),
      );
    }
  }

  /// 💾 GUARDA USUARIO LOCALMENTE
  Future<void> _guardarSesion(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', user.email ?? '');
  }

  /// 🔐 LOGIN
  Future<void> login() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      /// 👉 GUARDAR SESIÓN
      await _guardarSesion(cred.user!);

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(cred.user!.uid)
          .get();

      final rol = doc.data()?["rol"] ?? "consultor";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(rol: rol)),
      );
    } catch (e) {
      setState(() {
        error = "Correo o contraseña incorrectos";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  /// 📩 ENVÍO DE CORREO CORPORATIVO
  Future<void> enviarCorreoCorporativo(String email) async {
    final callable = FirebaseFunctions.instance.httpsCallable('enviarReset');

    await callable.call({"email": email});
  }

  /// 🔑 RECUPERAR PASSWORD
  void recuperarPassword() {
    final emailResetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Recuperar contraseña"),
        content: TextField(
          controller: emailResetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Ingresa tu correo"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailResetCtrl.text.isEmpty) return;

              try {
                await enviarCorreoCorporativo(emailResetCtrl.text.trim());

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Correo corporativo enviado")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error al enviar correo")),
                );
              }
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Image.asset('assets/logo.png', height: 80),
                      const SizedBox(height: 20),
                      const Text(
                        "SERMNE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: "Correo"),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Ingresar"),
                      ),
                      const SizedBox(height: 10),
                      if (error.isNotEmpty)
                        Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
