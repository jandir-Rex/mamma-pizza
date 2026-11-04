import Foundation

struct Direccion: Decodable, Hashable, Identifiable {
    let id: Int
    let zona: String
    let referencia: String?
    let lat: Double
    let lng: Double

    enum CodingKeys: String, CodingKey { case id, zona, referencia, lat, lng }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.flexInt(.id)
        zona = try c.decode(String.self, forKey: .zona)
        referencia = try? c.decodeIfPresent(String.self, forKey: .referencia)
        lat = try c.flexDouble(.lat)
        lng = try c.flexDouble(.lng)
    }
}
