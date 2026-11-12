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
    struct Archivo {
        let campo: String      // nombre del campo multipart (el backend espera "imagen")
        let nombre: String
        let mime: String
        let datos: Data
    }

    // MARK: - Request base

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
        return try await ejecutar(req)
    }

    private static func ejecutar(_ req: URLRequest) async throws -> Data {
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

    // MARK: - Atajos JSON

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

    // MARK: - Multipart (captura de Yape)

    /// POST multipart/form-data con campos de texto + un archivo.
    static func subir<T: Decodable>(_ path: String, campos: [String: String], archivo: Archivo) async throws -> T {
        guard let url = URL(string: AppConfig.apiBaseURL + path) else {
            throw APIError.mensaje("URL inválida")
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = HTTPMethod.POST.rawValue
        req.timeoutInterval = 40
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = KeychainStore.get("token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        func texto(_ s: String) { body.append(Data(s.utf8)) }
        for (clave, valor) in campos {
            texto("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(clave)\"\r\n\r\n\(valor)\r\n")
        }
        texto("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(archivo.campo)\"; filename=\"\(archivo.nombre)\"\r\nContent-Type: \(archivo.mime)\r\n\r\n")
        body.append(archivo.datos)
        texto("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        return try decodificar(try await ejecutar(req))
    }
}
