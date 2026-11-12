import Foundation
import Observation

@MainActor @Observable
final class CarritoStore {
    static let maxPorItem = 20

    private(set) var items: [ItemCarrito] = []

    var total: Double { items.reduce(0) { $0 + $1.subtotal } }
    var cantidadItems: Int { items.reduce(0) { $0 + $1.cantidad } }

    /// Agrega un item al carrito. Si ya existe una línea idéntica (mismo producto,
    /// variante, agregados y notas), suma la cantidad en lugar de crear una duplicada.
    /// Respeta el tope `maxPorItem` por línea.
    /// Devuelve `true` si la cantidad fue recortada por el tope (para que la UI avise).
    @discardableResult
    func agregar(_ nuevo: ItemCarrito) -> Bool {
        // Caso 1: ya existe una línea idéntica -> sumar cantidad respetando el tope
        if let i = items.firstIndex(where: { $0.esIdentico(a: nuevo) }) {
            let total = items[i].cantidad + nuevo.cantidad
            if total <= Self.maxPorItem {
                items[i].cantidad = total
                return false
            }
            // Se recortó: la línea queda en el tope, se avisa al llamador
            items[i].cantidad = Self.maxPorItem
            return true
        }

        // Caso 2: línea nueva -> crear con la cantidad pedida (topada al máximo)
        var item = nuevo
        let recortado = item.cantidad > Self.maxPorItem
        item.cantidad = min(item.cantidad, Self.maxPorItem)
        items.append(item)
        return recortado
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
