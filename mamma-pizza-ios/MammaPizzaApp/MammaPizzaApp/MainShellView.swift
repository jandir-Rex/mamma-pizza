import SwiftUI

struct MainShellView: View {
    @Environment(AppNavegacion.self) private var navegacion
    @Environment(AuthStore.self) private var auth

    var body: some View {
        @Bindable var nav = navegacion

        TabView(selection: $nav.tab) {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house") }
                .tag(TabPrincipal.inicio)

            MenuView()
                .tabItem { Label("Menú", systemImage: "fork.knife") }
                .tag(TabPrincipal.menu)

            PedidosHistorialView()
                .tabItem { Label("Pedidos", systemImage: "receipt") }
                .tag(TabPrincipal.pedidos)

            PerfilView()
                .tabItem { Label("Perfil", systemImage: "person") }
                .tag(TabPrincipal.perfil)
        }
        .tint(AppColors.primary)

        // 1) Carrito. Al cerrarse decide: checkout si hay sesión, login si no.
        .sheet(isPresented: $nav.mostrandoCarrito, onDismiss: {
            if nav.checkoutPendiente {
                nav.checkoutPendiente = false

                if auth.usuario != nil {
                    nav.mostrandoCheckout = true
                } else {
                    nav.pedirLogin(paraPagar: true)
                }
            }
        }) {
            CarritoSheet {
                nav.checkoutPendiente = true
            }
        }

        // 2) Login como hoja. Si venía de pagar, al cerrarse sigue al checkout.
        .sheet(isPresented: $nav.mostrandoLogin, onDismiss: {
            if nav.checkoutTrasLogin {
                nav.checkoutTrasLogin = false

                if auth.usuario != nil {
                    nav.mostrandoCheckout = true
                }
            }
        }) {
            LoginView(comoHoja: true)
        }

        // 3) Checkout
        .fullScreenCover(isPresented: $nav.mostrandoCheckout) {
            CheckoutFlowView()
        }
    }
}


/// Reemplaza el `Positioned(BarraCarritoFlotante)` del Stack de MainShell.
/// Se aplica DENTRO del NavigationStack de cada pestaña para que desaparezca al hacer push.

struct CarritoFlotante: ViewModifier {
    @Environment(AppNavegacion.self) private var nav

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            BarraCarritoFlotante {
                nav.mostrandoCarrito = true
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

extension View {
    func conCarritoFlotante() -> some View {
        modifier(CarritoFlotante())
    }
}
