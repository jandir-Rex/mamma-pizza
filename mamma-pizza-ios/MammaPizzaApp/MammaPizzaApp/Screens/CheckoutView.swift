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

    var body: some View {
        Form {
            Section("Dirección de entrega") {
                if cargando {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    ForEach(direcciones) { d in
                        Button {
                            seleccionadaId = d.id
                            error = nil
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(d.zona).foregroundStyle(AppColors.texto)
                                    if let r = d.referencia, !r.isEmpty {
                                        Text(r).font(.footnote).foregroundStyle(AppColors.gris)
                                    }
                                }
                                Spacer()
                                if d.id == seleccionadaId {
                                    Image(systemName: "checkmark").foregroundStyle(AppColors.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(d.id == seleccionadaId ? .isSelected : [])
                    }
                    Button { mostrandoMapa = true } label: {
                        Label("Agregar dirección en el mapa", systemImage: "mappin.and.ellipse")
                    }
                }
            }

            Section("Método de pago") {
                filaPago("Yape", "qrcode", activo: metodo == .yape) { metodo = .yape }
                filaPago("Efectivo", "banknote", activo: metodo == .efectivo) { metodo = .efectivo }
                filaPago("Tarjeta", "creditcard", activo: false, subtitulo: "Próximamente", habilitado: false) {}
            }

            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.footnote).foregroundStyle(AppColors.danger)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("Confirmar pedido")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack {
                    Text("Total a pagar").font(.headline)
                    Spacer()
                    Text(carrito.total.soles).font(.title3.weight(.heavy)).foregroundStyle(AppColors.primary)
                }
                Button { Task { await confirmar() } } label: {
                    HStack {
                        if enviando { ProgressView() }
                        Text("Confirmar pedido").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(enviando || carrito.items.isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(.bar)
        }
        .task { await cargarDirecciones() }
        .sheet(isPresented: $mostrandoMapa) {
            SeleccionarUbicacionView { nueva in
                direcciones.insert(nueva, at: 0)
                seleccionadaId = nueva.id
                error = nil
            }
        }
    }

    private func filaPago(_ titulo: String, _ simbolo: String, activo: Bool,
                          subtitulo: String? = nil, habilitado: Bool = true,
                          accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titulo).foregroundStyle(AppColors.texto)
                        if let subtitulo { Text(subtitulo).font(.caption).foregroundStyle(AppColors.gris) }
                    }
                } icon: {
                    Image(systemName: simbolo).foregroundStyle(activo ? AppColors.primary : AppColors.gris)
                }
                Spacer()
                if activo { Image(systemName: "checkmark").foregroundStyle(AppColors.primary) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!habilitado)
        .opacity(habilitado ? 1 : 0.45)
        .accessibilityAddTraits(activo ? .isSelected : [])
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
        guard let dir = direcciones.first(where: { $0.id == seleccionadaId }) else {
            error = "Agrega o elige una dirección de entrega"
            return
        }
        enviando = true
        error = nil
        defer { enviando = false }
        do {
            let pedido = try await PedidosService.crear(canal: "DELIVERY",
                                                        direccionId: dir.id,
                                                        metodoPago: metodo.rawValue,
                                                        items: carrito.items.map(\.payload))
            carrito.vaciar()
            onConfirmado(pedido.id, pedido.codigo)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
