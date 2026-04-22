import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(cred.user!.uid)
          .get();

      final rol = doc.data()?["rol"] ?? "consultor";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListaDuctos(rol: rol),
        ),
      );
    } catch (e) {
      setState(() {
        error = "Correo o contraseña incorrectos";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  void recuperarPassword() {
    final emailResetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Recuperar contraseña"),
        content: TextField(
          controller: emailResetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Ingresa tu correo",
          ),
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
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailResetCtrl.text.trim(),
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Correo de recuperación enviado"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
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

          /// 🔼 CONTENIDO PRINCIPAL
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
                      decoration: const InputDecoration(labelText: "Contraseña"),
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

          /// 🔽 BOTÓN SIEMPRE VISIBLE (AQUÍ ESTÁ LA CLAVE)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: TextButton(
              onPressed: recuperarPassword,
              child: const Text(
                "¿Olvidaste tu contraseña?",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
 