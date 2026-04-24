import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lista_ductos.dart';
import 'pages/dashboard_page.dart';
import 'admin_page.dart';
import 'login_page.dart';
import 'cambiar_password_page.dart'; // 👈 IMPORTANTE

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
          /// 🔐 CAMBIAR PASSWORD
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: "Cambiar contraseña",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CambiarPasswordPage(),
                ),
              );
            },
          ),

          /// 🔐 ADMIN PANEL
          if (widget.rol == "admin")
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: "Administración",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
            ),

          /// 🚪 LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),

      /// 🔥 CONTENIDO PRINCIPAL
      body: IndexedStack(
        index: index,
        children: [
          const DashboardPage(),
          ListaDuctos(rol: widget.rol),
        ],
      ),

      /// 🔽 NAVEGACIÓN
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Ductos",
          ),
        ],
      ),
    );
  }
}
