import Foundation

struct PrecioAgregado: Decodable, Hashable {
    let tamano: String
    let precio: Double

    enum CodingKeys: String, CodingKey { case tamano, precio }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tamano = try c.decode(String.self, forKey: .tamano)
        precio = try c.flexDouble(.precio)
    }
}

struct Agregado: Decodable, Hashable, Identifiable {
    let id: Int
    let nombre: String
    let disponible: Bool
    let precios: [PrecioAgregado]

    func precio(para tamano: String) -> Double? {
        precios.first { $0.tamano == tamano }?.precio
    }
}
