import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/header_pemex.dart';

String getCampo(Map data, List<String> keys) {
  for (var k in keys) {
    if (data[k] != null && data[k].toString().isNotEmpty) {
      return data[k].toString();
    }
  }
  return "";
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("ductos").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int bajo = 0, medio = 0, alto = 0;

        Map<String, int> fluidos = {};
        Map<String, int> condiciones = {};

        for (var doc in snapshot.data!.docs) {
          var d = doc.data();

          // 🔹 Riesgo
          var r = getCampo(d, ["NIVEL_DE_RIESGO"]);

          // 🔹 Fluido
          var f = getCampo(d, ["FLUIDO_PRINCIPAL", "FLUIDO PRINCIPAL"]);

          // 🔹 Condición operación
          var c = getCampo(d, [
            "CONDICION_DE_OPERACION",
            "CONDICIÓN DE OPERACIÓN",
          ]);

          // Clasificación riesgo
          if (r == "3") {
            alto++;
          } else if (r == "2") {
            medio++;
          } else {
            bajo++;
          }

          // Conteo fluidos
          if (f.isNotEmpty) {
            fluidos[f] = (fluidos[f] ?? 0) + 1;
          }

          // Conteo condiciones
          if (c.isNotEmpty) {
            condiciones[c] = (condiciones[c] ?? 0) + 1;
          }
        }

        int total = bajo + medio + alto;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            headerPemex(),

            const SizedBox(height: 10),

            const Text(
              "SERMNE - CONSULTA DUCTOS",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 6),

            // 🔥 TOTAL
            _totalCard(total),

            const SizedBox(height: 6),

            // 🔥 RIESGO
            Row(
              children: [
                _card("Bajo", bajo, Colors.green),
                _card("Medio", medio, Colors.orange),
                _card("Alto", alto, Colors.red),
              ],
            ),

            const SizedBox(height: 10),

            // 🔥 FLUIDOS
            _titulo("Distribución por Fluido"),
            _chips(fluidos),
            _graficaBarras(fluidos),

            const SizedBox(height: 6),

            // 🔥 CONDICIÓN
            _titulo("Condición de Operación"),
            _chips(condiciones),
            _graficaBarras(condiciones),
          ],
        );
      },
    );
  }

  // 🔷 TOTAL CARD
  Widget _totalCard(int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text("Total Ductos", style: TextStyle(color: Colors.white)),
          Text(
            "$total",
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 CARDS
  Widget _card(String t, int v, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(t, style: const TextStyle(color: Colors.white)),
            Text(
              "$v",
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔷 TITULO
  Widget _titulo(String t) {
    return Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }

  // 🔷 CHIPS
  Widget _chips(Map<String, int> data) {
    return Wrap(
      children: data.entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.all(4),
              child: Chip(label: Text("${e.key}: ${e.value}")),
            ),
          )
          .toList(),
    );
  }

  // 🔷 GRAFICA
  Widget _graficaBarras(Map<String, int> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const SizedBox();

    final max = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // 🔥 altura dinámica pero con límite
    final altura = (entries.length * 32).clamp(120, 300);

    return SizedBox(
      height: altura.toDouble(),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          double porcentaje = e.value / max;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // 🔹 Nombre
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 🔹 Barra
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: porcentaje,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 🔹 Valor
                Text(
                  "${e.value}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
