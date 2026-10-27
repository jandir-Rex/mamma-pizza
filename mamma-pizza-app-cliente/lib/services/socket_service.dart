import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static io_client.Socket? _socket;

  /// Devuelve el socket existente (conectado O conectándose) o crea uno nuevo.
  /// Antes, si el socket aún estaba conectándose, se creaba otro y quedaba
  /// el anterior huérfano con sus listeners.
  static Future<io_client.Socket?> conectar() async {
    if (_socket != null) return _socket;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return null;

    _socket = io_client.io(
      "http://localhost:4000", // ⚠️ Android emulador: http://10.0.2.2:4000 · celular real: IP de tu PC
      io_client.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({"token": token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket!.connect();
    return _socket;
  }

  /// Llamar al cerrar sesión (el token cambia).
  static void desconectar() {
    _socket?.dispose();
    _socket = null;
  }
}