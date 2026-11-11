import Foundation
import Observation

enum TabPrincipal: Hashable { case inicio, menu, pedidos, perfil }

@MainActor @Observable
final class AppNavegacion {
    var tab: TabPrincipal = .inicio
    var categoriaMenu = "Todas"

    var mostrandoCarrito = false
    var mostrandoCheckout = false
    /// Permite abrir Checkout justo DESPUÉS de que la hoja del carrito termine de cerrarse.
    var checkoutPendiente = false

    func irAMenu(_ categoria: String = "Todas") {
        categoriaMenu = categoria
        tab = .menu
    }
}
