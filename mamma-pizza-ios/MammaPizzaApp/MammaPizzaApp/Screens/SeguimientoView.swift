import SwiftUI
import SocketIO

@MainActor @Observable
final class SeguimientoViewModel {
    let pedidoId: Int
    var pedido: Pedido?
    var cargando = true
    var fallo = false

    private var idConnect: UUID?
    private var idActualizado: UUID?
    private var debounce: Task<Void, Never>?

    init(pedidoId: Int) { self.pedidoId = pedidoId }

    func cargar(silencioso: Bool = false) async {
        if !silencioso && pedido == nil { cargando = true }
        defer { cargando = false }
        do {
            pedido = try await PedidosService.obtenerPorId(pedidoId)
            fallo = false
        } catch {
            if pedido == nil && !Task.isCancelled { fallo = true }
        }
    }

    /// Vive mientras la vista esté en pantalla (se lanza con .task).
    /// Si el pedido ya no está activo (ENTREGADO o CANCELADO), no se conecta al socket
    /// ni hace polling: ahorra batería y datos cuando ya no hay nada que escuchar.
    func correr() async {
        await cargar()

        // Si el pedido ya está cerrado, no hay nada que escuchar.
        if pedido?.activo == false { return }

        escuchar()
        defer { dejarDeEscuchar() }

        // Red de seguridad: si el socket falla, refresca cada 30 s mientras el pedido siga activo.
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            if Task.isCancelled { break }
            if pedido?.activo == false { break }   // detener polling al cerrarse
            await cargar(silencioso: true)
        }
    }

    private func escuchar() {
        guard pedido?.activo != false else { return }
        guard let socket = SocketService.shared.conectar() else { return }

        idConnect = socket.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in self?.alConectar() }
        }
        idActualizado = socket.on("pedido:actualizado") { [weak self] data, _ in
            let id = ((data.first as? [String: Any])?["id"] as? NSNumber)?.intValue
            Task { @MainActor in self?.alActualizar(id) }
        }
        if socket.status == .connected { alConectar() }   // si ya estaba conectado, 'connect' no se repite
    }

    private func dejarDeEscuchar() {
        debounce?.cancel()
        let socket = SocketService.shared.socket
        if let idConnect { socket?.off(id: idConnect) }
        if let idActualizado { socket?.off(id: idActualizado) }
    }

    /// Al conectar y reconectar: volver a unirse a la sala del pedido y traer lo que se perdió.
    private func alConectar() {
        SocketService.shared.socket?.emit("pedido:seguir", pedidoId)
        Task { await cargar(silencioso: true) }
    }

    private func alActualizar(_ id: Int?) {
        guard id == pedidoId else { return }
        debounce?.cancel()   // varios eventos seguidos => una sola recarga
        debounce = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled { await cargar(silencioso: true) }
        }
    }
}

struct SeguimientoView: View {
    @State private var vm: SeguimientoViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(pedidoId: Int) {
        _vm = State(initialValue: SeguimientoViewModel(pedidoId: pedidoId))
    }

    var body: some View {
        Group {
            if vm.cargando && vm.pedido == nil {
                PizzaLoadingView(mensaje: "Cargando tu pedido...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let pedido = vm.pedido {
                ScrollView {
                    VStack(spacing: 16) {
                        // Pedido sin respuesta por mucho tiempo
                        if pedido.demorado {
                            AvisoDemora(enRevision: pedido.comprobanteEstado == "EN_REVISION")
                        }

                        // Yape: subir captura / en revisión / rechazado
                        if pedido.yapePendiente {
                            ComprobanteYapeCard(pedido: pedido) {
                                await vm.cargar(silencioso: true)
                            }
                        }

                        SeguimientoPedidoView(pedido: pedido)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await vm.cargar(silencioso: true) }
            } else {
                ContentUnavailableView {
                    Label(vm.fallo ? "No se pudo cargar el pedido" : "Pedido no encontrado",
                          systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Reintentar") { Task { await vm.cargar() } }
                }
            }
        }
        .background(AppColors.bg)
        .navigationTitle("Mi pedido")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let p = vm.pedido {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("#\(p.codigo)")
                        .font(.caption.weight(.semibold)).foregroundStyle(AppColors.gris)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .task { await vm.correr() }
        .onChange(of: scenePhase) { _, fase in
            if fase == .active { Task { await vm.cargar(silencioso: true) } }
        }
    }
}
