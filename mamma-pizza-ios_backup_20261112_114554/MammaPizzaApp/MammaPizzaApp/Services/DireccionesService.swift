import Foundation

enum DireccionesService {
    static func listar() async throws -> [Direccion] {
        try await APIClient.get("/direcciones")
    }

    static func crear(zona: String, referencia: String?, lat: Double, lng: Double) async throws -> Direccion {
        var body: [String: Any] = ["zona": zona, "lat": lat, "lng": lng]
        if let referencia, !referencia.isEmpty { body["referencia"] = referencia }
        return try await APIClient.post("/direcciones", body: body)
    }

    static func eliminar(id: Int) async throws {
        try await APIClient.delete("/direcciones/\(id)")
    }
}
