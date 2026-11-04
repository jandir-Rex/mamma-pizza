import Foundation

struct ItemPedido: Decodable, Hashable, Identifiable {
    let id = UUID()
    let cantidad: Int
    let precioUnitario: Double
    let nombre: String

    var subtotal: Double { precioUnitario * Double(cantidad) }

    private struct ProductoRef: Decodable { let nombre: String? }
    private struct VarianteRef: Decodable { let tamano: String?; let producto: ProductoRef? }
    private enum Keys: String, CodingKey {
        case cantidad, precioUnitario, nombre, nombreProducto, producto, variante, tamano
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        cantidad = try c.flexInt(.cantidad)
        precioUnitario = try c.flexDouble(.precioUnitario)

        let variante = try? c.decodeIfPresent(VarianteRef.self, forKey: .variante)
        let producto = (try? c.decodeIfPresent(ProductoRef.self, forKey: .producto)) ?? variante?.producto
        let base = (try? c.decodeIfPresent(String.self, forKey: .nombre))
            ?? (try? c.decodeIfPresent(String.self, forKey: .nombreProducto))
            ?? producto?.nombre ?? "Producto"
        let tamano = variante?.tamano ?? (try? c.decodeIfPresent(String.self, forKey: .tamano))
        nombre = tamano.map { "\(base) (\($0))" } ?? base
    }
}

struct Pedido: Decodable, Hashable, Identifiable {
    let id: Int
    let codigo: String
    let canal: String
    let estado: String
    let total: Double
    let createdAt: Date
    let items: [ItemPedido]
    /// Código de 4 dígitos que el cliente le dicta al repartidor (se genera al pasar a EN_CAMINO).
    let codigoConfirmacion: String?
    let confirmadoEn: Date?
    let intentosCodigoFallidos: Int

    var cantidadItems: Int { items.reduce(0) { $0 + $1.cantidad } }
    var esDelivery: Bool { canal == "DELIVERY" }
    var activo: Bool { estado != "ENTREGADO" && estado != "CANCELADO" }

    enum CodingKeys: String, CodingKey {
        case id, codigo, canal, estado, total, createdAt, items
        case codigoConfirmacion, confirmadoEn, intentosCodigoFallidos
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.flexInt(.id)
        codigo = try c.flexString(.codigo)
        canal = try c.decode(String.self, forKey: .canal)
        estado = try c.decode(String.self, forKey: .estado)
        total = try c.flexDouble(.total)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        items = (try? c.decodeIfPresent([ItemPedido].self, forKey: .items)) ?? []
        codigoConfirmacion = try? c.decodeIfPresent(String.self, forKey: .codigoConfirmacion)
        confirmadoEn = try? c.decodeIfPresent(Date.self, forKey: .confirmadoEn)
        intentosCodigoFallidos = (try? c.flexInt(.intentosCodigoFallidos)) ?? 0
    }
}
