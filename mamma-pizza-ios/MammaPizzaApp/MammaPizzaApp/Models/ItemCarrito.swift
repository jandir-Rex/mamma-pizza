import Foundation

struct ItemCarrito: Identifiable, Hashable {
    let id = UUID()
    let producto: Producto
    let variante: Variante
    let agregados: [Agregado]
    var cantidad: Int = 1
    var notas: String = ""

    var precioUnitario: Double {
        agregados.reduce(variante.precio) { $0 + ($1.precio(para: variante.tamano) ?? 0) }
    }
    var subtotal: Double { precioUnitario * Double(cantidad) }

    /// Compara dos líneas por su "contenido de negocio": mismo producto,
    /// misma variante, mismos agregados (sin importar orden) y mismas notas.
    /// Ignora `id` (UUID único de cada línea) y `cantidad` (que se suma al agrupar).
    func esIdentico(a otro: ItemCarrito) -> Bool {
        producto.id == otro.producto.id
            && variante.id == otro.variante.id
            && Set(agregados.map(\.id)) == Set(otro.agregados.map(\.id))
            && notas.trimmingCharacters(in: .whitespaces) == otro.notas.trimmingCharacters(in: .whitespaces)
    }
}
