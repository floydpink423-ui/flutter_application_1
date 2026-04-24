import 'package:flutter/material.dart';

String getCampo(Map data, String key) => (data[key] ?? "").toString();

Color getColor(String r) {
  if (r == "3") return Colors.red;
  if (r == "2") return Colors.orange;
  return Colors.green;
}
