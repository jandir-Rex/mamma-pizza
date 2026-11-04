import Foundation
import Observation

@MainActor @Observable
final class AuthStore {
    var usuario: Usuario?
    var cargando = true

    func intentarSesionGuardada() {
        if KeychainStore.get("token") != nil,
           let data = UserDefaults.standard.data(forKey: "usuario"),
           let u = try? JSONDecoder().decode(Usuario.self, from: data) {
            usuario = u
        }
        cargando = false
    }

    func login(email: String, password: String) async throws {
        let r = try await AuthService.login(email: email, password: password)
        guardarSesion(r)
    }

    func registro(nombre: String, email: String, password: String, telefono: String? = nil) async throws {
        let r = try await AuthService.registro(nombre: nombre, email: email, password: password, telefono: telefono)
        guardarSesion(r)
    }

    func actualizarPerfil(nombre: String? = nil, telefono: String? = nil) async throws {
        let actualizado = try await AuthService.actualizarPerfil(nombre: nombre, telefono: telefono)
        persistir(actualizado)
        usuario = actualizado
    }

    func logout() {
        SocketService.shared.desconectar()
        KeychainStore.remove("token")
        UserDefaults.standard.removeObject(forKey: "usuario")
        usuario = nil
    }

    private func guardarSesion(_ r: AuthService.Resultado) {
        KeychainStore.set(r.token, for: "token")
        persistir(r.usuario)
        usuario = r.usuario
    }

    private func persistir(_ u: Usuario) {
        if let data = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(data, forKey: "usuario")
        }
    }
}
