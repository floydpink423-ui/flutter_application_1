class Ducto {
  final String id;
  final String denominacion;
  final String activo;
  final String riesgo;

  Ducto({
    required this.id,
    required this.denominacion,
    required this.activo,
    required this.riesgo,
  });

  factory Ducto.fromMap(String id, Map data) {
    return Ducto(
      id: id,
      denominacion: data["DENOMINACION"] ?? "",
      activo: data["ACTIVO"] ?? "",
      riesgo: data["NIVEL_DE_RIESGO"] ?? "",
    );
  }
}
