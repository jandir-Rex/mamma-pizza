import SwiftUI

@main
struct MammaPizzaApp: App {
    @State private var auth = AuthStore()
    @State private var carrito = CarritoStore()
    @State private var menu = MenuStore()
    @State private var navegacion = AppNavegacion()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(carrito)
                .environment(menu)
                .environment(navegacion)
                .tint(AppColors.primary)
                .task { auth.intentarSesionGuardada() }
        }
    }
}

/// Equivale a `_Arrancador` de main.dart. Al cambiar `auth.usuario`
/// (login, registro o logout) la raíz cambia sola: no hace falta navegar a mano.
struct RootView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        Group {
            if auth.cargando {
                PizzaLoadingView(mensaje: "Cargando…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.bg)
            } else if auth.usuario != nil {
                MainShellView().transition(.opacity)
            } else {
                LoginView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: auth.usuario)
    }
}
