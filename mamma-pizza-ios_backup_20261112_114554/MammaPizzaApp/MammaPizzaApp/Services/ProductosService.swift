import Foundation

enum ProductosService {
    static func obtenerMenu() async throws -> [Producto] {
        try await APIClient.get("/productos/menu")
    }
    static func obtenerAgregados() async throws -> [Agregado] {
        try await APIClient.get("/agregados")
    }
}
