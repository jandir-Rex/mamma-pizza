import SwiftUI

struct DireccionesView: View {
    @State private var direcciones: [Direccion] = []
    @State private var cargando = true
    @State private var mostrandoMapa = false
    @State private var porEliminar: Direccion?
    @State private var error: String?

    var body: some View {
        Group {
            if cargando && direcciones.isEmpty {
                PizzaLoadingView(mensaje: "Cargando...").frame(maxWidth: .infinity, maxHeight: .infinity)
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
        if let lista = try? await DireccionesService.listar() { direcciones = lista }
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
