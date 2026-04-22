import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String rolSeleccionado = "consultor";

  /// 🔥 SOLO 3 ROLES
  final roles = ["admin", "editor", "consultor"];

  Map<String, String> cambiosRoles = {};

  /// ================= CREAR USUARIO =================
  Future<void> crearUsuario() async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(cred.user!.uid)
          .set({
        "email": emailCtrl.text.trim(),
        "rol": rolSeleccionado,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario creado correctamente")),
      );

      emailCtrl.clear();
      passCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ================= ACTUALIZAR ROL =================
  Future<void> actualizarRol(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .update({"rol": cambiosRoles[uid]});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rol actualizado")),
      );

      cambiosRoles.remove(uid);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administración de Usuarios")),
      body: Column(
        children: [
          headerPemex(),

          /// ================= CREAR =================
          Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text("Crear usuario",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: rolSeleccionado,
                    items: roles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => rolSeleccionado = value!);
                    },
                    decoration: const InputDecoration(labelText: "Rol"),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: crearUsuario,
                      child: const Text("Crear usuario"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          const Text("Usuarios registrados",
              style: TextStyle(fontWeight: FontWeight.bold)),

          /// ================= LISTA =================
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection("usuarios").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data();
                    final uid = doc.id;

                    String rolActual = data["rol"] ?? "consultor";

                    /// 🔥 SI EXISTE "user" → LO CONVERTIMOS
                    if (rolActual == "user") {
                      rolActual = "consultor";
                    }

                    String rolTemporal = cambiosRoles[uid] ?? rolActual;

                    return Card(
                      margin: const EdgeInsets.all(6),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(data["email"] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<String>(
                              value: rolTemporal,
                              items: roles
                                  .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  cambiosRoles[uid] = value!;
                                });
                              },
                            ),
                            if (cambiosRoles.containsKey(uid))
                              ElevatedButton(
                                onPressed: () => actualizarRol(uid),
                                child: const Text("Actualizar"),
                              )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

/// ================= HEADER =================
Widget headerPemex() {
  return Column(
    children: [
      Image.asset('assets/logo.png', height: 60),
      const Text(
        "Gerencia de Mantenimiento, Confiabilidad y Construcción",
        textAlign: TextAlign.center,
      ),
      const Text(
        "SERMNE-DUCTOS",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
}
