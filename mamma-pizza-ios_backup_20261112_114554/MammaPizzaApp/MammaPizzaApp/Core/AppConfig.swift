import Foundation

enum AppConfig {
    // Simulador: localhost funciona. iPhone físico: usa la IP de tu Mac (ej. 192.168.1.X).
    static let host = "http://localhost:4000"
    static var apiBaseURL: String { host + "/api" }
    static var socketURL: URL { URL(string: host)! }

    static var mapboxToken: String {
        return "pk.eyJ1IjoiamFuZGlyeDIwIiwiYSI6ImNtdW9wOXNxcTAxYjYyeW9sbTM4NnZkbnMifQ.VdTWqvTSrPPOvsDER1_CcQ"
    }
    
    /// Solo tokens públicos (pk.). Un sk. nunca debe ir dentro de la app.
    static var mapboxConfigurado: Bool { mapboxToken.hasPrefix("pk.") }
}
