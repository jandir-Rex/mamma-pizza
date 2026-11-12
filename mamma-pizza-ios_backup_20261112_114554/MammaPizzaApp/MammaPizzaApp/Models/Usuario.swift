import Foundation

struct Usuario: Codable, Hashable, Identifiable {
    let id: Int
    let nombre: String
    let email: String
    let rol: String
}
