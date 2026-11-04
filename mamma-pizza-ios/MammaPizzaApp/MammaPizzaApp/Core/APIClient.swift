import Foundation

struct APIError: LocalizedError {
    let mensaje: String
    var errorDescription: String? { mensaje }
    static func mensaje(_ m: String) -> APIError { APIError(mensaje: m) }
}

enum HTTPMethod: String { case GET, POST, PATCH, DELETE }

extension JSONDecoder {
    /// Acepta fechas ISO8601 con y sin milisegundos.
    static let api: JSONDecoder = {
        let conMs = ISO8601DateFormatter()
        conMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let sinMs = ISO8601DateFormatter()
        sinMs.formatOptions = [.withInternetDateTime]
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let f = conMs.date(from: s) ?? sinMs.date(from: s) { return f }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Fecha inválida: \(s)"))
        }
        return d
    }()
}

enum APIClient {
    static func request(_ method: HTTPMethod, _ path: String, body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: AppConfig.apiBaseURL + path) else {
            throw APIError.mensaje("URL inválida")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainStore.get("token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let data: Data, resp: URLResponse
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch { throw APIError.mensaje("No se pudo conectar con el servidor. Revisa tu conexión.") }

        guard let http = resp as? HTTPURLResponse else { throw APIError.mensaje("Respuesta inválida") }
        if http.statusCode >= 400 {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw APIError.mensaje((json?["error"] as? String) ?? "Error inesperado")
        }
        return data
    }

    private static func decodificar<T: Decodable>(_ data: Data) throws -> T {
        do { return try JSONDecoder.api.decode(T.self, from: data) }
        catch { throw APIError.mensaje("Respuesta inesperada del servidor") }
    }

    static func get<T: Decodable>(_ path: String) async throws -> T {
        try decodificar(try await request(.GET, path))
    }
    static func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        try decodificar(try await request(.POST, path, body: body))
    }
    static func patch<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try decodificar(try await request(.PATCH, path, body: body))
    }
    static func delete(_ path: String) async throws {
        _ = try await request(.DELETE, path)
    }
}
