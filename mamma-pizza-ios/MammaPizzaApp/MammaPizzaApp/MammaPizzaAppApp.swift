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


/// Raíz de la app. El splash se muestra encima al arrancar.

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var mostrandoSplash = true

    var body: some View {
        ZStack {
            if auth.cargando {
                AppColors.bg.ignoresSafeArea()
            } else {
                MainShellView().transition(.opacity)
            }

            if mostrandoSplash || auth.cargando {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        mostrandoSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}
