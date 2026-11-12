import SwiftUI

struct DireccionesView: View {
    @State private var direcciones: [Direccion] = []
    @State private var cargando = true
    @State private var mostrandoMapa = false
    @State private var porEliminar: Direccion?
    @State private var error: String?      // errores de eliminación (alerta)
    @State private var errorCarga: String? // errores de carga (ContentUnavailableView)

    var body: some View {
        Group {
            if cargando && direcciones.isEmpty {
                PizzaLoadingView(mensaje: "Cargando...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if direcciones.isEmpty && errorCarga != nil {
                // Falla de red: el usuario no tiene direcciones en memoria porque la carga falló.
                // Distinguimos este caso del "realmente no tiene direcciones".
                ContentUnavailableView {
                    Label("No pudimos cargar tus direcciones", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorCarga ?? "Revisa tu conexión e inténtalo de nuevo.")
                } actions: {
                    Button("Reintentar") { Task { await cargar() } }
                        .buttonStyle(.borderedProminent)
                    Button("Agregar dirección") { mostrandoMapa = true }
                }
            } else if direcciones.isEmpty {
                ContentUnavailableView {
                    Label("No tienes direcciones guardadas", systemImage: "mappin.slash")
                } description: {
                    Text("Agrega una para pedir delivery más rápido")
                } actions: {
                    Button("Agregar dirección") { mostrandoMapa = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(direcciones) { d in
                        FilaDireccion(direccion: d)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions {
                                Button("Eliminar", role: .destructive) { porEliminar = d }
                            }
                            .contextMenu {
                                Button("Eliminar", systemImage: "trash", role: .destructive) { porEliminar = d }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Button { mostrandoMapa = true } label: {
                        Label("Agregar dirección", systemImage: "plus")
                    }
                    .buttonStyle(.primario)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.bar)
                }
            }
        }
        .fondoApp()
        .navigationTitle("Mis direcciones")
        .refreshable { await cargar() }
        .task { await cargar() }
        .sheet(isPresented: $mostrandoMapa) {
            SeleccionarUbicacionView { _ in Task { await cargar() } }
        }
        .confirmationDialog("¿Eliminar dirección?",
                            isPresented: Binding(get: { porEliminar != nil },
                                                 set: { if !$0 { porEliminar = nil } }),
                            titleVisibility: .visible, presenting: porEliminar) { d in
            Button("Eliminar", role: .destructive) { Task { await eliminar(d) } }
            Button("Cancelar", role: .cancel) { porEliminar = nil }
        } message: { Text($0.zona) }
        .alert("No se pudo eliminar",
               isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }

    private func cargar() async {
        if direcciones.isEmpty { cargando = true }
        defer { cargando = false }
        do {
            let lista = try await DireccionesService.listar()
            direcciones = lista
            errorCarga = nil
        } catch {
            // No silenciar: si falla la red, el usuario debe saberlo.
            // Mantenemos las direcciones que ya estaban para no perder contexto.
            self.errorCarga = "No pudimos cargar tus direcciones. Revisa tu conexión."
        }
    }

    private func eliminar(_ d: Direccion) async {
        porEliminar = nil
        do {
            try await DireccionesService.eliminar(id: d.id)
            await cargar()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct FilaDireccion: View {
    let direccion: Direccion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.cacaoTexto)
                .frame(width: 40, height: 40)
                .background(AppColors.kraftClaro, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(direccion.zona).font(.body.weight(.semibold)).foregroundStyle(AppColors.texto)
                if let r = direccion.referencia, !r.isEmpty {
                    Text(r).font(.footnote).foregroundStyle(AppColors.gris).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .tarjeta(padding: 14)
        .accessibilityElement(children: .combine)
    }
}
