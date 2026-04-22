import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userController = TextEditingController();
  TextEditingController passController = TextEditingController();

  String error = "";

  final usuarios = {
    "admin": {"pass": "1234", "rol": "admin"},
    "ductos": {"pass": "1234", "rol": "user"},
  };

  Future<void> login() async {
    String user = userController.text.trim();
    String pass = passController.text.trim();

    if (usuarios.containsKey(user) && usuarios[user]!["pass"] == pass) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("logged", true);
      await prefs.setString("rol", usuarios[user]!["rol"].toString());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PantallaDucto()),
      );
    } else {
      setState(() {
        error = "Credenciales incorrectas";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 80),
            SizedBox(height: 10),
            Text(
              "SERMNE",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Gerencia de Mantenimiento, Confiabilidad y Construcción",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            Text(
              "Coordinación de Ingeniería de Rendimiento de Equipos",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 30),
            TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: "Usuario",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Ingresar")),
            SizedBox(height: 10),
            Text(error, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
