import 'package:flutter/material.dart';

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
