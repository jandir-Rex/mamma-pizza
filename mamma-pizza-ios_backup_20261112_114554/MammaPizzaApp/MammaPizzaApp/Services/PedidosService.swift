import Foundation

struct ConfigPago: Decodable {
    let yapeNumero: String?
    let yapeTitular: String?
}

enum PedidosService {
    static func misPedidos() async throws -> [Pedido] {
        try await APIClient.get("/pedidos/mios")
    }

    static func obtenerPorId(_ id: Int) async throws -> Pedido {
        try await APIClient.get("/pedidos/\(id)")
    }

    static func crear(canal: String, direccionId: Int? = nil, mesaId: Int? = nil,
                      metodoPago: String, pagaCon: Double? = nil,
                      items: [[String: Any]]) async throws -> Pedido {
        var body: [String: Any] = ["canal": canal, "metodoPago": metodoPago, "items": items]
        if let direccionId { body["direccionId"] = direccionId }
        if let mesaId { body["mesaId"] = mesaId }
        if let pagaCon { body["pagaCon"] = pagaCon }
        return try await APIClient.post("/pedidos", body: body)
    }

    static func configPago() async throws -> ConfigPago {
        try await APIClient.get("/pedidos/config-pago")
    }

    /// Sube la captura del Yape (multipart) con el nombre de quien yapeó.
    @discardableResult
    static func subirComprobante(_ pedidoId: Int, captura: Data, yapeNombre: String) async throws -> Pedido {
        try await APIClient.subir(
            "/pedidos/\(pedidoId)/comprobante",
            campos: ["yapeNombre": yapeNombre],
            archivo: .init(campo: "imagen", nombre: "yape.jpg", mime: "image/jpeg", datos: captura)
        )
    }
}
