import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();

  String message = "";
  bool loading = false;

  Future<void> cambiarPassword() async {
    setState(() {
      loading = true;
      message = "";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          message = "Usuario no autenticado";
          loading = false;
        });
        return;
      }

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassCtrl.text.trim(),
      );

      // 🔐 Re-autenticación obligatoria
      await user.reauthenticateWithCredential(cred);

      // 🔁 Cambio de contraseña
      await user.updatePassword(newPassCtrl.text.trim());

      setState(() {
        message = "Contraseña actualizada correctamente";
      });

      currentPassCtrl.clear();
      newPassCtrl.clear();
    } catch (e) {
      setState(() {
        message = "Error: contraseña actual incorrecta";
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cambiar contraseña"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña actual",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : cambiarPassword,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Actualizar contraseña"),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
