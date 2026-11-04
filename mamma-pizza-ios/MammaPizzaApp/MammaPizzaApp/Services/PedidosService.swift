import Foundation

enum PedidosService {
    static func misPedidos() async throws -> [Pedido] {
        try await APIClient.get("/pedidos/mios")
    }

    static func obtenerPorId(_ id: Int) async throws -> Pedido {
        try await APIClient.get("/pedidos/\(id)")
    }

    static func crear(canal: String, direccionId: Int? = nil, mesaId: Int? = nil,
                      metodoPago: String, items: [[String: Any]]) async throws -> Pedido {
        var body: [String: Any] = ["canal": canal, "metodoPago": metodoPago, "items": items]
        if let direccionId { body["direccionId"] = direccionId }
        if let mesaId { body["mesaId"] = mesaId }
        return try await APIClient.post("/pedidos", body: body)
    }
}
