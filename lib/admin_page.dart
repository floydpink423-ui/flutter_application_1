import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final auth = AuthService();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String rol = "consultor";

  Future<void> crearUsuario() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;

    await auth.crearUsuario(
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
      rol: rol,
    );

    emailCtrl.clear();
    passCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usuario creado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Admin"),
      ),
      body: Column(
        children: [
          /// ================= CREAR USUARIO =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: rol,
                  isExpanded: true,
                  items: ["admin", "editor", "consultor"]
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => rol = value!);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: crearUsuario,
                  child: const Text("Crear usuario"),
                ),
              ],
            ),
          ),

          const Divider(),

          /// ================= LISTA DE USUARIOS =================
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('usuarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("Sin usuarios"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final user = docs[i];

                    final rolActual = user['rol'] ?? "consultor";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(user['email']),
                        subtitle: Row(
                          children: [
                            const Text("Rol: "),
                            Chip(
                              label: Text(rolActual),
                              backgroundColor: rolActual == "admin"
                                  ? Colors.red
                                  : rolActual == "editor"
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ],
                        ),

                        /// 🔧 ACCIONES
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// 🔄 CAMBIAR ROL
                            DropdownButton<String>(
                              value: ["admin", "editor", "consultor"]
                                      .contains(rolActual)
                                  ? rolActual
                                  : "consultor",
                              items: ["admin", "editor", "consultor"]
                                  .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(user.id)
                                    .update({"rol": value});
                              },
                            ),

                            /// 🔑 RESET PASSWORD
                            IconButton(
                              icon: const Icon(Icons.lock_reset,
                                  color: Colors.blue),
                              onPressed: () async {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                        email: user['email']);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Correo de recuperación enviado")),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
