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

    /// Login como hoja. Si `checkoutTrasLogin` es true, al ingresar sigue al pago.
    var mostrandoLogin = false
    var checkoutTrasLogin = false

    func irAMenu(_ categoria: String = "Todas") {
        categoriaMenu = categoria
        tab = .menu
    }

    func pedirLogin(paraPagar: Bool = false) {
        checkoutTrasLogin = paraPagar
        mostrandoLogin = true
    }
}
