class AppConfig {
  /// Teléfono del local: lo usan el botón SOS y "Llamar al local". CÁMBIALO por el real.
  static const telefonoLocal = '+51900000000';

  /// Intentos máximos del código de entrega (igual que MAX_INTENTOS_CODIGO del backend)
  static const maxIntentosCodigo = 3;

  /// Cada cuánto se refresca la lista de entregas (segundos)
  static const refrescoEntregasSeg = 15;
}