import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CambiarPasswordPage extends StatefulWidget {
  const CambiarPasswordPage({super.key});

  @override
  State<CambiarPasswordPage> createState() => _CambiarPasswordPageState();
}

class _CambiarPasswordPageState extends State<CambiarPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassController.text.trim(),
      );

      // 🔐 Reautenticar
      await user.reauthenticateWithCredential(cred);

      // 🔄 Cambiar password
      await user.updatePassword(_newPassController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña actualizada correctamente")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error";

      if (e.code == 'wrong-password') {
        mensaje = "La contraseña actual es incorrecta";
      } else if (e.code == 'weak-password') {
        mensaje = "La nueva contraseña es muy débil";
      } else if (e.code == 'requires-recent-login') {
        mensaje = "Vuelve a iniciar sesión";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error inesperado")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cambiar contraseña"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔐 Password actual
              TextFormField(
                controller: _currentPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña actual",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),

              const SizedBox(height: 15),

              /// 🔐 Nueva password
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nueva contraseña",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Campo obligatorio";
                  }
                  if (value.length < 6) {
                    return "Mínimo 6 caracteres";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              /// 🔐 Confirmar password
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirmar contraseña",
                ),
                validator: (value) {
                  if (value != _newPassController.text) {
                    return "Las contraseñas no coinciden";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              /// 🔘 Botón
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _cambiarPassword,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Actualizar contraseña"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
