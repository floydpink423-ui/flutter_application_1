import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'admin_page.dart';
import 'change_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// ================= UTIL =================
String getCampo(Map data, String limpio, String viejo) {
  return (data[limpio] ?? data[viejo] ?? "").toString();
}

String getCampoSeguro(Map data, String limpio, String viejo,
    {String defaultValue = ""}) {
  return (data[limpio] ?? data[viejo] ?? defaultValue).toString();
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
  final user = TextEditingController();
  final pass = TextEditingController();
  final auth = AuthService();

  String error = "";
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final userFirebase = await auth.login(user.text.trim(), pass.text.trim());

      final rol = await auth.getRol(userFirebase!.uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListaDuctos(rol: rol),
        ),
      );
    } catch (e) {
      setState(() => error = "Error de login");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 80),
            const SizedBox(height: 20),
            const Text("SERMNE",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: user,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Ingresar"),
            ),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

/// ================= LISTA =================
class ListaDuctos extends StatefulWidget {
  final String rol;

  const ListaDuctos({super.key, required this.rol});

  @override
  _ListaDuctosState createState() => _ListaDuctosState();
}

class _ListaDuctosState extends State<ListaDuctos> {
  TextEditingController buscador = TextEditingController();

  Color getColor(String riesgo) {
    if (riesgo == "3") return Colors.red;
    if (riesgo == "2") return Colors.orange;
    if (riesgo == "1") return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SERMNE"),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          if (widget.rol == "admin")
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("ductos").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final filtrados = docs.where((doc) {
            var data = doc.data();
            String texto = buscador.text.toLowerCase();

            return getCampo(data, "DUCTO", "DUCTO")
                    .toLowerCase()
                    .contains(texto) ||
                getCampo(data, "DENOMINACION", "DENOMINACIÓN")
                    .toLowerCase()
                    .contains(texto);
          }).toList();

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 70),
                    const SizedBox(height: 10),
                    const Text("SERMNE-CONSULTA DUCTOS",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: buscador,
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Buscar ducto...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ...filtrados.map((doc) {
                var data = doc.data();

                String riesgo = getCampoSeguro(
                  data,
                  "NIVEL_DE_RIESGO",
                  "NIVEL DE RIESGO",
                  defaultValue: "1",
                );

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getColor(riesgo),
                    ),
                    title: Text(getCampo(data, "DUCTO", "DUCTO")),
                    subtitle:
                        Text(getCampo(data, "DENOMINACION", "DENOMINACIÓN")),
                    trailing: const Icon(Icons.visibility),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarDucto(
                            doc: doc,
                            soloLectura: widget.rol == "consultor",
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// ================= DETALLE =================
class EditarDucto extends StatefulWidget {
  final DocumentSnapshot doc;
  final bool soloLectura;

  const EditarDucto({
    super.key,
    required this.doc,
    required this.soloLectura,
  });

  @override
  _EditarDuctoState createState() => _EditarDuctoState();
}

class _EditarDuctoState extends State<EditarDucto> {
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    var data = widget.doc.data() as Map<String, dynamic>;

    controllers = {
      "DUCTO": TextEditingController(text: getCampo(data, "DUCTO", "DUCTO")),
      "DENOMINACION": TextEditingController(
          text: getCampo(data, "DENOMINACION", "DENOMINACIÓN")),
      "ACTIVO": TextEditingController(text: getCampo(data, "ACTIVO", "ACTIVO")),
      "SERVICIO":
          TextEditingController(text: getCampo(data, "SERVICIO", "SERVICIO")),
      "TIPO_DE_DUCTO": TextEditingController(
          text: getCampo(data, "TIPO_DE_DUCTO", "TIPO DE DUCTO")),
      "ORIGEN_ENVIO": TextEditingController(
          text: getCampo(data, "ORIGEN_ENVIO", "ORIGEN (ENVIO)")),
      "DESTINO_RECIBO": TextEditingController(
          text: getCampo(data, "DESTINO_RECIBO", "DESTINO (RECIBO)")),
      "LONGITUD_KM": TextEditingController(
          text: getCampo(data, "LONGITUD_KM", "LONGITUD (km)")),
      "DIAMETRO_NOMINAL__PULGADAS": TextEditingController(
          text: getCampo(data, "DIAMETRO_NOMINAL__PULGADAS",
              "DIAMETRO NOMINAL [PULGADAS]")),
      "FLUIDO_PRINCIPAL": TextEditingController(
          text: getCampo(data, "FLUIDO_PRINCIPAL", "FLUIDO PRINCIPAL")),
      "FLUJO__DEL_LIQUIDO_MBPD": TextEditingController(
          text: getCampo(
              data, "FLUJO__DEL_LIQUIDO_MBPD", "FLUJO DEL LIQUIDO (MBPD)")),
      "FLUJO_DEL_GAS_MMPCD": TextEditingController(
          text: getCampo(data, "FLUJO_DEL_GAS_MMPCD", "FLUJO DEL GAS (MMPCD)")),
      "PRESION_DE_DISENO_KGCM²": TextEditingController(
          text: getCampo(
              data, "PRESION_DE_DISENO_KGCM²", "PRESIÓN DE DISEÑO (Kg/cm²)")),
      "PRESION_DE_OPERACION_KGCM²": TextEditingController(
          text: getCampo(data, "PRESION_DE_OPERACION_KGCM²",
              "PRESIÓN DE OPERACIÓN (kg/cm²)")),
      "TEMPERATURA_DE_DISENO_C": TextEditingController(
          text: getCampo(
              data, "TEMPERATURA_DE_DISENO_C", "TEMPERATURA DE DISEÑO (°C)")),
      "TEMPERATURA_OPERACION_C": TextEditingController(
          text: getCampo(
              data, "TEMPERATURA_OPERACION_C", "TEMPERATURA OPERACIÓN (°C)")),
      "FECHA_ANALISIS_DE_RIESGO": TextEditingController(
          text: getCampo(
              data, "FECHA_ANALISIS_DE_RIESGO", "FECHA ANALISIS DE RIESGO")),
      "CRITERIO_ECONOMICO_SAP": TextEditingController(
          text: getCampo(
              data, "CRITERIO_ECONOMICO_SAP", "CRITERIO ECONÓMICO (SAP)")),
      "NIVEL_DE_RIESGO": TextEditingController(
        text: getCampoSeguro(
          data,
          "NIVEL_DE_RIESGO",
          "NIVEL DE RIESGO",
          defaultValue: "1",
        ),
      ),
    };
  }

  Widget campo(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controllers[key],
        readOnly: widget.soloLectura,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> guardarCambios() async {
    if (widget.soloLectura) return;

    Map<String, dynamic> datos = {};

    controllers.forEach((key, controller) {
      datos[key] = controller.text;
    });

    await FirebaseFirestore.instance
        .collection("ductos")
        .doc(widget.doc.id)
        .update(datos);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.soloLectura ? "Detalle del ducto" : "Editar ducto"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            campo("Ducto", "DUCTO"),
            campo("Denominación", "DENOMINACION"),
            campo("Activo", "ACTIVO"),
            campo("Servicio", "SERVICIO"),
            campo("Tipo de ducto", "TIPO_DE_DUCTO"),
            campo("Origen", "ORIGEN_ENVIO"),
            campo("Destino", "DESTINO_RECIBO"),
            campo("Longitud (km)", "LONGITUD_KM"),
            campo("Diámetro", "DIAMETRO_NOMINAL__PULGADAS"),
            campo("Fluido", "FLUIDO_PRINCIPAL"),
            campo("Flujo líquido", "FLUJO__DEL_LIQUIDO_MBPD"),
            campo("Flujo gas", "FLUJO_DEL_GAS_MMPCD"),
            campo("Presión diseño", "PRESION_DE_DISENO_KGCM²"),
            campo("Presión operación", "PRESION_DE_OPERACION_KGCM²"),
            campo("Temp diseño", "TEMPERATURA_DE_DISENO_C"),
            campo("Temp operación", "TEMPERATURA_OPERACION_C"),
            campo("Fecha análisis", "FECHA_ANALISIS_DE_RIESGO"),
            campo("Criterio económico", "CRITERIO_ECONOMICO_SAP"),
            campo("Riesgo", "NIVEL_DE_RIESGO"),
            const SizedBox(height: 20),
            if (!widget.soloLectura)
              ElevatedButton(
                onPressed: guardarCambios,
                child: const Text("Guardar cambios"),
              ),
          ],
        ),
      ),
    );
  }
}
