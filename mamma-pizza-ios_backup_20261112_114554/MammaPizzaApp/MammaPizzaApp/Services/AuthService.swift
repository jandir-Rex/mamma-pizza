import Foundation

enum AuthService {
    struct Resultado { let token: String; let usuario: Usuario }
    private struct Respuesta: Decodable { let token: String; let usuario: Usuario }

    static func login(email: String, password: String) async throws -> Resultado {
        let r: Respuesta = try await APIClient.post("/auth/login", body: ["email": email, "password": password])
        return Resultado(token: r.token, usuario: r.usuario)
    }

    static func registro(nombre: String, email: String, password: String, telefono: String?) async throws -> Resultado {
        var body: [String: Any] = ["nombre": nombre, "email": email, "password": password]
        if let telefono, !telefono.isEmpty { body["telefono"] = telefono }
        let r: Respuesta = try await APIClient.post("/auth/registro", body: body)
        return Resultado(token: r.token, usuario: r.usuario)
    }

    static func actualizarPerfil(nombre: String?, telefono: String?) async throws -> Usuario {
        var body: [String: Any] = [:]
        if let nombre, !nombre.isEmpty { body["nombre"] = nombre }
        if let telefono { body["telefono"] = telefono }
        return try await APIClient.patch("/auth/perfil", body: body)
    }
}
