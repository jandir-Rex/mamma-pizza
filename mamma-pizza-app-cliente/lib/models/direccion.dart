class Direccion {
  final int id;
  final String zona;
  final String? referencia;
  final double lat;
  final double lng;

  Direccion({required this.id, required this.zona, this.referencia, required this.lat, required this.lng});

  factory Direccion.fromJson(Map<String, dynamic> json) => Direccion(
        id: json["id"],
        zona: json["zona"],
        referencia: json["referencia"],
        lat: double.parse(json["lat"].toString()),
        lng: double.parse(json["lng"].toString()),
      );
}