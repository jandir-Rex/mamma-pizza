import SwiftUI

enum RutaCheckout: Hashable {
    case exito(id: Int, codigo: String)
    case seguimiento(id: Int)
}

struct CheckoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ruta: [RutaCheckout] = []

    var body: some View {
        NavigationStack(path: $ruta) {
            CheckoutView { id, codigo in ruta = [.exito(id: id, codigo: codigo)] }
                .navigationDestination(for: RutaCheckout.self) { destino in
                    switch destino {
                    case .exito(let id, let codigo):
                        PedidoExitoView(codigo: codigo,
                                        onVerSeguimiento: { ruta = [.seguimiento(id: id)] },
                                        onVolver: { dismiss() })
                            .navigationBarBackButtonHidden()
                    case .seguimiento(let id):
                        SeguimientoView(pedidoId: id)
                            .navigationBarBackButtonHidden()
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Listo") { dismiss() }.fontWeight(.semibold)
                                }
                            }
                    }
                }
        }
    }
}
