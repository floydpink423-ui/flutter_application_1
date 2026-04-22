// ================= MAIN FINAL CORREGIDO =================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// ================= UTIL =================
String getCampo(Map data, String key) => (data[key] ?? "").toString();

Color getColor(String r) {
  if (r == "3") return Colors.red;
  if (r == "2") return Colors.orange;
  return Colors.green;
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

/// ================= APP =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

/// ================= LOGIN =================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String msg = "";

  Future<void> login() async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: pass.text.trim());

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(cred.user!.uid)
          .get();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(rol: doc["rol"] ?? "consultor"),
        ),
      );
    } catch (e) {
      setState(() => msg = "Error de acceso");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 80),
              TextField(
                  decoration: const InputDecoration(labelText: "Correo"),
                  controller: email),
              TextField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                  controller: pass),
              ElevatedButton(onPressed: login, child: const Text("Ingresar")),
              Text(msg, style: const TextStyle(color: Colors.red))
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= HOME =================
class HomePage extends StatefulWidget {
  final String rol;
  const HomePage({super.key, required this.rol});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SERMNE - (${widget.rol})"),
        actions: [
          if (widget.rol == "admin")
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminPage())),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),

      /// 🔥 CAMBIO: PASAR ROL
      body: index == 0 ? const DashboardPage() : ListaDuctos(rol: widget.rol),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Ductos"),
        ],
      ),
    );
  }
}

/// ================= DASHBOARD =================
/// (SIN CAMBIOS)
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("ductos").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        int bajo = 0, medio = 0, alto = 0;
        Map<String, int> fluidos = {};

        for (var doc in snapshot.data!.docs) {
          var d = doc.data() as Map<String, dynamic>;

          var r = getCampo(d, "NIVEL_DE_RIESGO");
          var f = getCampo(d, "FLUIDO_PRINCIPAL");

          if (r == "3")
            alto++;
          else if (r == "2")
            medio++;
          else
            bajo++;

          if (f.trim().isNotEmpty) {
            fluidos[f] = (fluidos[f] ?? 0) + 1;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            headerPemex(),
            Row(
              children: [
                _card("Bajo", bajo, Colors.green),
                _card("Medio", medio, Colors.orange),
                _card("Alto", alto, Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Por Fluido",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: fluidos.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: Chip(label: Text("${e.key}: ${e.value}")),
                      ))
                  .toList(),
            )
          ],
        );
      },
    );
  }

  Widget _card(String t, int v, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(t, style: const TextStyle(color: Colors.white)),
            Text("$v",
                style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}

/// ================= LISTA BONITA =================
class ListaDuctos extends StatefulWidget {
  final String rol;
  const ListaDuctos({super.key, required this.rol});

  @override
  State<ListaDuctos> createState() => _ListaDuctosState();
}

class _ListaDuctosState extends State<ListaDuctos> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        headerPemex(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(labelText: "Buscar ducto"),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection("ductos").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data.values
                    .any((v) => v.toString().toLowerCase().contains(search));
              }).toList();

              return ListView(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final color = getColor(getCampo(data, "NIVEL_DE_RIESGO"));

                  return Card(
                    color: color.withOpacity(0.3),
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(getCampo(data, "DENOMINACION")),
                      subtitle: Text(getCampo(data, "ACTIVO")),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarDucto(
                            doc: d,
                            rol: widget.rol,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        )
      ],
    );
  }
}

/// ================= EDITAR =================
class EditarDucto extends StatefulWidget {
  final DocumentSnapshot doc;
  final String rol;

  const EditarDucto({
    super.key,
    required this.doc,
    required this.rol,
  });

  @override
  State<EditarDucto> createState() => _EditarDuctoState();
}

class _EditarDuctoState extends State<EditarDucto> {
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    data.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });
  }

  Future<void> guardar() async {
    try {
      Map<String, dynamic> updated = {};

      controllers.forEach((k, v) {
        final text = v.text.trim();

        String cleanKey = k
            .replaceAll("/", "")
            .replaceAll("[", "")
            .replaceAll("]", "")
            .replaceAll("(", "")
            .replaceAll(")", "")
            .replaceAll("°", "")
            .replaceAll(".", "")
            .trim();

        if (int.tryParse(text) != null) {
          updated[cleanKey] = int.parse(text);
        } else if (double.tryParse(text) != null) {
          updated[cleanKey] = double.parse(text);
        } else {
          updated[cleanKey] = text;
        }
      });

      await FirebaseFirestore.instance
          .collection("ductos")
          .doc(widget.doc.id)
          .update(updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cambios guardados correctamente")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final soloLectura = widget.rol == "consultor";

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Ducto")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  headerPemex(),
                  ...controllers.entries.map((e) => TextField(
                        controller: e.value,
                        readOnly: soloLectura,
                        decoration: InputDecoration(labelText: e.key),
                      )),
                ],
              ),
            ),
          ),
          if (!soloLectura)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: guardar,
                child: const Text("Guardar cambios"),
              ),
            )
        ],
      ),
    );
  }
}
