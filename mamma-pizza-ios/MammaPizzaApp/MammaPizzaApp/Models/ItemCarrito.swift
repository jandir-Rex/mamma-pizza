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
}
