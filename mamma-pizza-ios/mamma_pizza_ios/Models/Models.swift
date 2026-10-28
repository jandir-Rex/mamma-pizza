import Foundation

struct Producto: Identifiable, Codable, Hashable {
    let id: Int
    let nombre: String
    let descripcion: String?
    let categoriaId: Int
    let imagenUrl: String?
    let disponible: Bool
    let variantes: [ProductoVariante]
}

struct Pedido: Identifiable, Codable {
    let id: String
    let codigo: String
    let fecha: String
    let total: Double
    let estado: String
    let items: [ItemPedido]
    
    var fechaFormateada: String {
        // Devuelve la fecha o una representación sencilla
        return fecha
    }
}

struct ItemCarrito: Identifiable {
    let id = UUID()
    let producto: Producto
    let variante: ProductoVariante
    var cantidad: Int
    let agregados: [AgregadoSeleccionado]
    let notas: String?
    
    var subtotal: Double {
        let precioAgregados = agregados.reduce(0) { $0 + $1.precio }
        return (variante.precio + precioAgregados) * Double(cantidad)
    }
}