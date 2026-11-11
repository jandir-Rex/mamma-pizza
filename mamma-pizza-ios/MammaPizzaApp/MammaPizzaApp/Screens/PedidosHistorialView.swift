import SwiftUI

struct PedidosHistorialView: View {
    @State private var pedidos: [Pedido] = []
    @State private var cargando = true
    @State private var error: String?

    private var activos: [Pedido] { pedidos.filter(\.activo) }
    private var anteriores: [Pedido] { pedidos.filter { !$0.activo } }

    var body: some View {
        NavigationStack {
            Group {
                if cargando && pedidos.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error, pedidos.isEmpty {
                    ContentUnavailableView {
                        Label("No se pudieron cargar tus pedidos", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Reintentar") { Task { await cargar() } }
                    }
                } else if pedidos.isEmpty {
                    ContentUnavailableView("Todavía no tienes pedidos", systemImage: "receipt",
                                           description: Text("Realiza tu primer pedido para verlo aquí"))
                } else {
                    List {
                        if !activos.isEmpty {
                            Section("En curso") { ForEach(activos) { FilaPedido(pedido: $0) } }
                        }
                        if !anteriores.isEmpty {
                            Section("Anteriores") { ForEach(anteriores) { FilaPedido(pedido: $0) } }
                        }
                    }
                    .contentMargins(.bottom, 70, for: .scrollContent)
                }
            }
            .background(AppColors.bg)
            .navigationTitle("Mis pedidos")
            .navigationDestination(for: Int.self) { SeguimientoView(pedidoId: $0) }
            .refreshable { await cargar() }
            .conCarritoFlotante()
        }
        .task { await cargar() }   // se ejecuta cada vez que la pestaña aparece
    }

    private func cargar() async {
        if pedidos.isEmpty { cargando = true }
        error = nil
        defer { cargando = false }
        do {
            pedidos = try await PedidosService.misPedidos().sorted { $0.createdAt > $1.createdAt }
        } catch {
            if Task.isCancelled { return }
            self.error = error.localizedDescription
        }
    }
}

private struct FilaPedido: View {
    let pedido: Pedido

    var body: some View {
        NavigationLink(value: pedido.id) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pedido #\(pedido.codigo)").font(.headline)
                    Spacer()
                    Text(EstadoPedidoUI.etiqueta(pedido.estado))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EstadoPedidoUI.color(pedido.estado))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(EstadoPedidoUI.color(pedido.estado).opacity(0.12), in: Capsule())
                }
                Label("\(pedido.esDelivery ? "Delivery" : "Recojo") · \(pedido.cantidadItems) items",
                      systemImage: pedido.esDelivery ? "scooter" : "storefront")
                    .font(.footnote).foregroundStyle(AppColors.gris)
                if pedido.activo {
                    Text(EstadoPedidoUI.subtitulo(pedido.estado))
                        .font(.footnote.weight(.medium)).foregroundStyle(AppColors.primary)
                }
                HStack {
                    Text(pedido.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote).foregroundStyle(AppColors.gris)
                    Spacer()
                    Text(pedido.total.soles).font(.headline).foregroundStyle(AppColors.primary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
