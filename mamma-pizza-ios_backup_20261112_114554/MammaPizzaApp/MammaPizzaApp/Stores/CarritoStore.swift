import Foundation
import Observation

@MainActor @Observable
final class CarritoStore {
    static let maxPorItem = 20

    private(set) var items: [ItemCarrito] = []

    var total: Double { items.reduce(0) { $0 + $1.subtotal } }
    var cantidadItems: Int { items.reduce(0) { $0 + $1.cantidad } }

    func agregar(_ nuevo: ItemCarrito) {
        var item = nuevo
        item.cantidad = min(item.cantidad, Self.maxPorItem)
        items.append(item)
    }

    func quitar(id: UUID) {
        items.removeAll { $0.id == id }
    }

    /// Suma o resta. Si baja de 1 se elimina; si supera el tope, no hace nada.
    func cambiarCantidad(id: UUID, delta: Int) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let nueva = items[i].cantidad + delta
        if nueva < 1 { items.remove(at: i) }
        else if nueva <= Self.maxPorItem { items[i].cantidad = nueva }
    }

    func vaciar() { items.removeAll() }
}
