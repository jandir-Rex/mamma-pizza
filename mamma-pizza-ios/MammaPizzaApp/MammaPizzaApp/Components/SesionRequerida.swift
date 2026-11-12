import SwiftUI

/// Si no hay sesión, reemplaza el contenido por una invitación a iniciar sesión.
struct SesionRequerida: ViewModifier {
    @Environment(AuthStore.self) private var auth
    @Environment(AppNavegacion.self) private var nav
    let titulo: String
    let mensaje: String
    let icono: String

    func body(content: Content) -> some View {
        if auth.usuario == nil {
            ContentUnavailableView {
                Label(titulo, systemImage: icono)
            } description: {
                Text(mensaje)
            } actions: {
                Button("Iniciar sesión") { nav.pedirLogin() }
                    .buttonStyle(.primario)
                    .frame(maxWidth: 260)
            }
            .fondoApp()
        } else {
            content
        }
    }
}

extension View {
    func sesionRequerida(titulo: String, mensaje: String, icono: String) -> some View {
        modifier(SesionRequerida(titulo: titulo, mensaje: mensaje, icono: icono))
    }
}
