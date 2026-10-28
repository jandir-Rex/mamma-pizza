import SwiftUI

struct OrdersView: View {
    @State private var pedidos: [Pedido] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.primary)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundColor(.red)
                            Button("Reintentar") {
                                Task { await cargarPedidos() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.primary)
                        }
                    } else if pedidos.isEmpty {
                        ContentUnavailableView(
                            "Sin pedidos",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Aún no has realizado ningún pedido.")
                        )
                    } else {
                        List(pedidos) { pedido in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pedido #\(pedido.codigo)")
                                    .font(.headline)
                                Text("Estado: \(pedido.estado)")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.primary)
                                Text("Total: S/. \(pedido.total.toStringAsFixed(2))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 4)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Mis Pedidos")
            .task {
                await cargarPedidos()
            }
        }
    }
    
    private func cargarPedidos() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            self.pedidos = try await NetworkService.shared.fetch(endpoint: "/pedidos/usuario")
        } catch {
            self.errorMessage = "No se pudieron cargar tus pedidos."
        }
    }
}
