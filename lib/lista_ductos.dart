import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/header_pemex.dart';

String getCampo(Map data, String key) => (data[key] ?? "").toString();

Color getColor(String r) {
  if (r == "3") return Colors.red;
  if (r == "2") return Colors.orange;
  return Colors.green;
}

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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((d) {
                final data = d.data();
                return data.values
                    .any((v) => v.toString().toLowerCase().contains(search));
              }).toList();

              return ListView(
                children: docs.map((d) {
                  final data = d.data();
                  final color = getColor(getCampo(data, "NIVEL_DE_RIESGO"));

                  return Card(
                    color: color.withOpacity(0.3),
                    child: ListTile(
                      title: Text(getCampo(data, "DENOMINACION")),
                      subtitle: Text(getCampo(data, "ACTIVO")),
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
