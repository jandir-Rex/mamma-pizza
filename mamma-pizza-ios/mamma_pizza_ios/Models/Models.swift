import Foundation
import SwiftUI

enum RolUsuario: String, Codable {
    case cliente = "CLIENTE"
    case admin = "ADMIN"
    case repartidor = "REPARTIDOR"
    case mozo = "MOZO"
}

struct AgregadoPrecio: Identifiable, Codable, Hashable {
    let id: Int
    let agregadoId: Int
    let tamano: String
    let precio: Double
}

struct CrearPedidoItemRequest: Encodable {
    let productoVarianteId: Int
    let cantidad: Int
    let notas: String?
}

struct AgregadoSeleccionado: Identifiable, Codable, Hashable {
    let id: Int
    let nombre: String
    let precio: Double
}

struct PedidoCreadoResponse: Decodable {
    let id: Int
    let codigo: String
    let total: Double
    let estado: EstadoPedido
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError
}

struct Categoria: Identifiable, Codable, Hashable {
    let id: Int
    let nombre: String
    let productos: [Producto]?
}

struct ProductoVariante: Identifiable, Codable, Hashable {
    let id: Int
    let productoId: Int
    let tamano: String
    let precio: Double
    let disponible: Bool
}

struct EstadoPedidoUI {
    static func color(para estado: String) -> Color {
        switch estado.uppercased() {
        case "PENDIENTE_PAGO":
            return AppColors.warning
        case "CONFIRMADO":
            return AppColors.info
        case "EN_PREPARACION":
            return Color(hex: "E07A00")
        case "EN_CAMINO":
            return AppColors.purple
        case "ENTREGADO":
            return AppColors.success
        case "CANCELADO":
            return AppColors.danger
        default:
            return AppColors.gray
        }
    }

    static func etiqueta(para estado: String) -> String {
        switch estado.uppercased() {
        case "PENDIENTE_PAGO": return "Pendiente de pago"
        case "CONFIRMADO": return "Confirmado"
        case "EN_PREPARACION": return "En preparación"
        case "EN_CAMINO": return "En camino"
        case "ENTREGADO": return "Entregado"
        case "CANCELADO": return "Cancelado"
        default: return estado
        }
    }
}

enum MetodoPago: String, Codable {
    case yape = "YAPE"
    case efectivo = "EFECTIVO"
    case tarjeta = "TARJETA"
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

struct Agregado: Identifiable, Codable, Hashable {
    let id: Int
    let nombre: String
    let disponible: Bool
    let precios: [AgregadoPrecio]?
}

enum EstadoPedido: String, Codable {
    case pendientePago = "PENDIENTE_PAGO"
    case confirmado = "CONFIRMADO"
    case enPreparacion = "EN_PREPARACION"
    case enCamino = "EN_CAMINO"
    case entregado = "ENTREGADO"
    case cancelado = "CANCELADO"
    
    var titulo: String {
        switch self {
        case .pendientePago: return "Pendiente de Pago"
        case .confirmado: return "Confirmado"
        case .enPreparacion: return "En la Cocina 🍕"
        case .enCamino: return "En Camino 🛵"
        case .entregado: return "¡Entregado!"
        case .cancelado: return "Cancelado"
        }
    }
}

struct CrearPedidoRequest: Encodable {
    let canal: CanalPedido
    let direccionId: Int?
    let mesaId: Int?
    let items: [CrearPedidoItemRequest]
}

struct ItemPedido: Identifiable, Codable {
    var id: String { nombre }
    let nombre: String
    let cantidad: Int
    let precio: Double
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

enum CanalPedido: String, Codable {
    case delivery = "DELIVERY"
    case salon = "SALON"
}

struct Producto: Identifiable, Codable, Hashable {
    let id: Int
    let nombre: String
    let descripcion: String?
    let categoriaId: Int
    let imagenUrl: String?
    let disponible: Bool
    let variantes: [ProductoVariante]
}