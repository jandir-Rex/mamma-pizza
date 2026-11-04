import Foundation

struct Variante: Decodable, Hashable, Identifiable {
    let id: Int
    let tamano: String
    let precio: Double
    let disponible: Bool

    enum CodingKeys: String, CodingKey { case id, tamano, precio, disponible }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.flexInt(.id)) ?? 0
        tamano = (try? c.decode(String.self, forKey: .tamano)) ?? ""
        precio = (try? c.flexDouble(.precio)) ?? 0
        disponible = (try? c.decode(Bool.self, forKey: .disponible)) ?? true
    }
}

struct Producto: Decodable, Hashable, Identifiable {
    let id: Int
    let nombre: String
    let descripcion: String?
    let imagenUrl: String?
    let categoriaNombre: String
    let variantes: [Variante]

    private struct Categoria: Decodable { let nombre: String? }
    enum CodingKeys: String, CodingKey { case id, nombre, descripcion, imagenUrl, categoria, variantes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.flexInt(.id)) ?? 0
        nombre = (try? c.decode(String.self, forKey: .nombre)) ?? ""
        descripcion = try? c.decodeIfPresent(String.self, forKey: .descripcion)
        let img = (try? c.decodeIfPresent(String.self, forKey: .imagenUrl))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        imagenUrl = (img?.isEmpty ?? true) ? nil : img
        let cat = try? c.decodeIfPresent(Categoria.self, forKey: .categoria)
        categoriaNombre = cat?.nombre ?? "Otros"
        variantes = (try? c.decodeIfPresent([Variante].self, forKey: .variantes)) ?? []
    }

    /// Precio mínimo entre variantes disponibles; si todas están agotadas, el mínimo general.
    var precioDesde: Double {
        let disponibles = variantes.filter(\.disponible).map(\.precio)
        let base = disponibles.isEmpty ? variantes.map(\.precio) : disponibles
        return base.min() ?? 0
    }

    var agotado: Bool { variantes.isEmpty || variantes.allSatisfy { !$0.disponible } }
}
