import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passCtrl = TextEditingController();
  String msg = "";
  bool loading = false;

  Future<void> reset() async {
    setState(() {
      loading = true;
      msg = "";
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: passCtrl.text.trim(),
      );

      setState(() {
        msg = "Contraseña actualizada correctamente";
      });
    } catch (e) {
      setState(() {
        msg = "Link inválido o expirado";
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva contraseña"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : reset,
              child: const Text("Actualizar"),
            ),
            const SizedBox(height: 10),
            Text(msg, style: const TextStyle(color: Colors.red))
          ],
        ),
      ),
    );
  }
}
