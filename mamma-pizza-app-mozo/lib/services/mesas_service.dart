import '../core/api_client.dart';
import '../models/mesa.dart';

class MesasService {
  static Future<List<Mesa>> estado() async {
    final data = await ApiClient.get("/mesas/estado");
    return (data as List).map((m) => Mesa.fromJson(m)).toList();
  }
}