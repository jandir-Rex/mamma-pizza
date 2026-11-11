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

/// Raíz de la app. Al cambiar `auth.usuario` (login, registro o logout)
/// la pantalla cambia sola. El splash se muestra encima al arrancar.
struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var mostrandoSplash = true

    var body: some View {
        ZStack {
            Group {
                if auth.cargando {
                    AppColors.bg.ignoresSafeArea()
                } else if auth.usuario != nil {
                    MainShellView().transition(.opacity)
                } else {
                    LoginView().transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.28), value: auth.usuario)

            if mostrandoSplash || auth.cargando {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) { mostrandoSplash = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}
