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
            VStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 76, height: 76)
                    .background(AppColors.kraftClaro, in: Circle())
                    .padding(.bottom, 6)

                Text(titulo)
                    .font(.marca(.title2))
                    .foregroundStyle(AppColors.texto)

                Text(mensaje)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.gris)
                    .multilineTextAlignment(.center)

                Button("Iniciar sesión") { nav.pedirLogin() }
                    .buttonStyle(.primario)
                    .frame(width: 260)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
