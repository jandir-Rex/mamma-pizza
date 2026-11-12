import SwiftUI

struct PedidosHistorialView: View {
    @State private var pedidos: [Pedido] = []
    @State private var cargando = true
    @State private var error: String?

    // NUEVO: observar el estado de autenticación
    @Environment(AuthStore.self) private var auth

    private var activos: [Pedido] { pedidos.filter(\.activo) }
    private var anteriores: [Pedido] { pedidos.filter { !$0.activo } }

    var body: some View {
        NavigationStack {
            Group {
                if cargando && pedidos.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error, pedidos.isEmpty {
                    ContentUnavailableView {
                        Label("No se pudieron cargar tus pedidos", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Reintentar") {
                            Task { await cargar() }
                        }
                    }
                } else if pedidos.isEmpty {
                    ContentUnavailableView(
                        "Todavía no tienes pedidos",
                        systemImage: "receipt",
                        description: Text("Realiza tu primer pedido para verlo aquí")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 28) {
                            if !activos.isEmpty {
                                seccion("En curso", activos)
                            }

                            if !anteriores.isEmpty {
                                seccion("Anteriores", anteriores)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .contentMargins(.bottom, 70, for: .scrollContent)
                }
            }
            .fondoApp()
            .navigationTitle("Mis pedidos")
            .navigationDestination(for: Int.self) {
                SeguimientoView(pedidoId: $0)
            }
            .refreshable {
                await cargar()
            }
            .conCarritoFlotante()
        }
        .task {
            await cargar()
        }

        // NUEVO: limpiar pedidos cuando se cierra sesión
        .onChange(of: auth.usuario == nil) { _, sinSesion in
            if sinSesion {
                pedidos = []
            }
        }

        // NUEVO: solicitar autenticación para consultar pedidos
        .sesionRequerida(
            titulo: "Tus pedidos",
            mensaje: "Inicia sesión para ver y seguir tus pedidos",
            icono: "receipt"
        )
    }

    private func seccion(_ titulo: String, _ lista: [Pedido]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion(titulo)

            ForEach(lista) { p in
                NavigationLink(value: p.id) {
                    FilaPedido(pedido: p)
                }
                .buttonStyle(.presion)
            }
        }
    }

    private func cargar() async {
        if pedidos.isEmpty {
            cargando = true
        }

        error = nil
        defer { cargando = false }

        do {
            pedidos = try await PedidosService.misPedidos()
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            if Task.isCancelled { return }
            self.error = error.localizedDescription
        }
    }
}


private struct FilaPedido: View {
    let pedido: Pedido

    var body: some View {
        let color = EstadoPedidoUI.color(pedido.estado)

        HStack(alignment: .top, spacing: 14) {
            Image(systemName: EstadoPedidoUI.icono(pedido.estado))
                .font(.headline)
                .foregroundStyle(EstadoPedidoUI.colorTexto(pedido.estado))
                .frame(width: 44, height: 44)
                .background(
                    color.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pedido #\(pedido.codigo)")
                        .font(.headline)
                        .foregroundStyle(AppColors.texto)

                    Spacer()

                    Text(pedido.total.soles)
                        .font(.precio(.headline))
                        .foregroundStyle(AppColors.primary)
                }

                InsigniaEstado(estado: pedido.estado)

                Text("\(pedido.esDelivery ? "Delivery" : "Recojo") · \(pedido.cantidadItems) items · \(pedido.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(AppColors.gris)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.grisClaro)
                .padding(.top, 14)
        }
        .tarjeta(padding: 14)
        .overlay {
            if pedido.activo {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(color.opacity(0.45), lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
