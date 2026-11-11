import SwiftUI

struct CheckoutView: View {
    var onConfirmado: (_ id: Int, _ codigo: String) -> Void

    @Environment(CarritoStore.self) private var carrito
    @Environment(\.dismiss) private var dismiss

    private enum MetodoPago: String { case yape = "YAPE", efectivo = "EFECTIVO" }

    @State private var direcciones: [Direccion] = []
    @State private var seleccionadaId: Int?
    @State private var metodo: MetodoPago = .yape
    @State private var cargando = true
    @State private var enviando = false
    @State private var error: String?
    @State private var mostrandoMapa = false

    // Pago
    @State private var captura: CapturaYape?
    @State private var yapeNombre = ""
    @State private var montoExacto = true
    @State private var pagaConTexto = ""

    /// Motivo visible por el que el botón está deshabilitado (nil = listo).
    private var motivoBloqueo: String? {
        if cargando { return "Cargando tus direcciones…" }
        if seleccionadaId == nil { return "Elige o agrega una dirección de entrega" }
        switch metodo {
        case .yape:
            if captura == nil { return "Adjunta la captura de tu Yape" }
            if yapeNombre.trimmingCharacters(in: .whitespaces).count < 2 { return "Indica el nombre de quien yapeó" }
        case .efectivo:
            if !montoExacto {
                guard let v = parsearMonto(pagaConTexto), v >= carrito.total else {
                    return "Indica con cuánto pagarás (mínimo \(carrito.total.soles))"
                }
            }
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                resumen
                seccionDireccion
                seccionPago
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fondoApp()
        .navigationTitle("Confirmar pedido")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
        }
        .safeAreaInset(edge: .bottom) { barraInferior }
        .interactiveDismissDisabled(enviando)
        .task { await cargarDirecciones() }
        .sheet(isPresented: $mostrandoMapa) {
            SeleccionarUbicacionView { nueva in
                direcciones.insert(nueva, at: 0)
                seleccionadaId = nueva.id
                error = nil
            }
        }
    }

    // MARK: Secciones

    private var resumen: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Tu pedido")
            VStack(spacing: 10) {
                ForEach(carrito.items, id: \.id) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(item.cantidad)×")
                            .font(.subheadline.weight(.bold)).foregroundStyle(AppColors.primary)
                        Text("\(item.producto.nombre) · \(item.variante.tamano.capitalizadoLimpio)")
                            .font(.subheadline).lineLimit(2)
                        Spacer(minLength: 8)
                        Text(item.subtotal.soles).font(.subheadline).foregroundStyle(AppColors.gris)
                    }
                }
            }
            .tarjeta()
        }
    }

    private var seccionDireccion: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Dirección de entrega")
            if cargando {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                if direcciones.isEmpty {
                    Text("Aún no tienes direcciones. Agrega dónde recibirás tu pedido.")
                        .font(.subheadline).foregroundStyle(AppColors.gris)
                }
                ForEach(direcciones) { d in
                    FilaSeleccion(icono: "location.fill",
                                  titulo: d.zona,
                                  subtitulo: d.referencia,
                                  activo: d.id == seleccionadaId) {
                        seleccionadaId = d.id
                        error = nil
                    }
                }
                Button { mostrandoMapa = true } label: {
                    Label("Agregar dirección en el mapa", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.secundario)
            }
        }
    }

    private var seccionPago: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Método de pago")
            FilaSeleccion(icono: "qrcode", titulo: "Yape",
                          subtitulo: "Paga con QR y adjunta tu captura",
                          activo: metodo == .yape) { elegir(.yape) }
            FilaSeleccion(icono: "banknote", titulo: "Efectivo",
                          subtitulo: "Pagas al recibir tu pedido",
                          activo: metodo == .efectivo) { elegir(.efectivo) }
            FilaSeleccion(icono: "creditcard", titulo: "Tarjeta",
                          subtitulo: "Próximamente",
                          activo: false, habilitado: false) {}

            Group {
                switch metodo {
                case .yape:
                    YapeFormularioView(total: carrito.total, captura: $captura, nombre: $yapeNombre)
                case .efectivo:
                    PagaConSelector(total: carrito.total, exacto: $montoExacto, texto: $pagaConTexto)
                }
            }
            .tarjeta()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .animation(.snappy, value: metodo)
    }

    private var barraInferior: some View {
        VStack(spacing: 12) {
            if let error { BannerError(error) }

            HStack(alignment: .firstTextBaseline) {
                Text("Total a pagar").font(.subheadline).foregroundStyle(AppColors.gris)
                Spacer()
                Text(carrito.total.soles).font(.precio(.title)).foregroundStyle(AppColors.primary)
            }

            if let motivo = motivoBloqueo, !enviando {
                Label(motivo, systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(AppColors.gris)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button { Task { await confirmar() } } label: {
                HStack(spacing: 8) {
                    if enviando { ProgressView() } else { Image(systemName: "checkmark.circle.fill") }
                    Text("Confirmar pedido")
                }
            }
            .buttonStyle(.primario)
            .disabled(carrito.items.isEmpty || motivoBloqueo != nil)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: Lógica

    private func elegir(_ m: MetodoPago) {
        metodo = m
        error = nil
    }

    private func cargarDirecciones() async {
        cargando = true
        defer { cargando = false }
        if let lista = try? await DireccionesService.listar() {
            direcciones = lista
            if seleccionadaId == nil { seleccionadaId = lista.first?.id }
        }
    }

    private func confirmar() async {
        guard !enviando else { return }
        guard let dir = direcciones.first(where: { $0.id == seleccionadaId }) else {
            error = "Agrega o elige una dirección de entrega"
            return
        }

        var pagaCon: Double?
        var capturaYape: CapturaYape?
        let nombreYape = yapeNombre.trimmingCharacters(in: .whitespaces)

        switch metodo {
        case .yape:
            guard let c = captura else { error = "Adjunta la captura de tu Yape"; return }
            guard nombreYape.count >= 2 else { error = "Indica el nombre de quien yapeó"; return }
            capturaYape = c
        case .efectivo:
            if !montoExacto {
                guard let v = parsearMonto(pagaConTexto), v >= carrito.total else {
                    error = "Indica con cuánto pagarás (mínimo \(carrito.total.soles))"
                    return
                }
                pagaCon = v
            }
        }

        enviando = true
        error = nil
        defer { enviando = false }
        do {
            let pedido = try await PedidosService.crear(canal: "DELIVERY",
                                                        direccionId: dir.id,
                                                        metodoPago: metodo.rawValue,
                                                        pagaCon: pagaCon,
                                                        items: carrito.items.map(\.payload))

            // El pedido ya existe: si la subida falla, se reintenta desde el seguimiento.
            if let capturaYape {
                _ = try? await PedidosService.subirComprobante(pedido.id,
                                                               captura: capturaYape.datos,
                                                               yapeNombre: nombreYape)
            }

            carrito.vaciar()
            onConfirmado(pedido.id, pedido.codigo)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
