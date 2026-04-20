import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Datos simulados (temporal)
  final List<Map<String, dynamic>> usuarios = [
    {"email": "admin@test.com", "rol": "admin"},
    {"email": "user@test.com", "rol": "usuario"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: ListView.builder(
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final user = usuarios[index];

          return ListTile(
            title: Text(user['email']),
            subtitle: Text("Rol: ${user['rol']}"),
            trailing: const Icon(Icons.person),
          );
        },
      ),
    );
  }
}
