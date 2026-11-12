import Foundation

enum AppConfig {
    // URL pública de InstaBox (apunta al puerto 4000 de tu Mac).
    // Para desarrollo local, puedes cambiar esto a "http://localhost:4000".
    static let host = "https://4000-agqyupg2egluipq35eyr4qw4aa.instabox.tech"
    static var apiBaseURL: String { host + "/api" }
    static var socketURL: URL { URL(string: host)! }

    static var mapboxToken: String {
        return "pk.eyJ1IjoiamFuZGlyeDIwIiwiYSI6ImNtdW9wOXNxcTAxYjYyeW9sbTM4NnZkbnMifQ.VdTWqvTSrPPOvsDER1_CcQ"
    }
    
    /// Solo tokens públicos (pk.). Un sk. nunca debe ir dentro de la app.
    static var mapboxConfigurado: Bool { mapboxToken.hasPrefix("pk.") }
}
