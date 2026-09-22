import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static io_client.Socket? _socket;

  static Future<io_client.Socket?> conectar() async {
    if (_socket != null && _socket!.connected) return _socket;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return null;

    _socket = io_client.io(
      "http://10.0.2.2:4000",
      io_client.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({"token": token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    return _socket;
  }

  static void desconectar() {
    _socket?.disconnect();
    _socket = null;
  }
}