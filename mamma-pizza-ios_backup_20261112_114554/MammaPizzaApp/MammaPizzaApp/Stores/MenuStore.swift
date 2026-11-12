import Foundation
import Observation

@MainActor @Observable
final class MenuStore {
    var productos: [Producto] = []
    var agregados: [Agregado] = []
    var cargando = false
    var cargado = false
    var error: String?

    func cargar() async {
        guard !cargando else { return }
        cargando = true
        error = nil
        defer { cargando = false }

        do {
            productos = try await ProductosService.obtenerMenu()
            cargado = true
        } catch {
            // Si ya había datos, se conservan y no se muestra error.
            if productos.isEmpty { self.error = "No se pudo cargar el menú" }
            return
        }
        // Los agregados son opcionales: si fallan, el menú sigue funcionando.
        if let a = try? await ProductosService.obtenerAgregados() { agregados = a }
    }
}
