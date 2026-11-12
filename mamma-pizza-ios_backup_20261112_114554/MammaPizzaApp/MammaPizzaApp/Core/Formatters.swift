import Foundation

extension Double {
    var soles: String { String(format: "S/. %.2f", self) }
}

extension String {
    /// "media_luna" -> "Media luna"
    var capitalizadoLimpio: String {
        let limpio = replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
        guard let primera = limpio.first else { return limpio }
        return primera.uppercased() + limpio.dropFirst()
    }
}

/// Equivalente a iconoCategoria() de tony_widgets.dart (SF Symbols).
func iconoCategoria(_ nombre: String) -> String {
    let n = nombre.lowercased()
    if n.contains("bebida") { return "cup.and.saucer.fill" }
    if n.contains("postre") { return "birthday.cake.fill" }
    return "fork.knife"
}
