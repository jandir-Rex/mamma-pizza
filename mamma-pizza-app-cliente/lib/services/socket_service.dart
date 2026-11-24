import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class SocketService {
  static io_client.Socket? _socket;

  /// Devuelve el socket existente (conectado O conectándose) o crea uno nuevo.
  static Future<io_client.Socket?> conectar() async {
    if (_socket != null) return _socket;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return null;

    _socket = io_client.io(
      ApiClient.serverUrl, // https://mamma-pizza-backend.onrender.com
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