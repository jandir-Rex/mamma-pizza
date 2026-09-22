class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  Usuario({required this.id, required this.nombre, required this.email, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json["id"],
      nombre: json["nombre"],
      email: json["email"],
      rol: json["rol"],
    );
  }
}