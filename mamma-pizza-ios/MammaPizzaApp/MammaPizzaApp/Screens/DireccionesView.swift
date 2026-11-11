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
                ContentUnavailableView("No tienes direcciones guardadas", systemImage: "mappin.slash",
                                       description: Text("Agrega una para pedir delivery más rápido"))
            } else {
                List {
                    ForEach(direcciones) { d in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(d.zona, systemImage: "mappin.circle.fill")
                                .foregroundStyle(AppColors.texto)
                            if let r = d.referencia, !r.isEmpty {
                                Text(r).font(.footnote).foregroundStyle(AppColors.gris).padding(.leading, 32)
                            }
                        }
                        .swipeActions {
                            Button("Eliminar", role: .destructive) { porEliminar = d }
                        }
                    }
                }
            }
        }
        .background(AppColors.bg)
        .navigationTitle("Mis direcciones")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { mostrandoMapa = true } label: { Label("Agregar", systemImage: "plus") }
            }
        }
        .refreshable { await cargar() }
        .task { await cargar() }
        .sheet(isPresented: $mostrandoMapa) {
            SeleccionarUbicacionView { _ in Task { await cargar() } }
        }
        .confirmationDialog("¿Eliminar dirección?", isPresented: .constant(porEliminar != nil),
                            titleVisibility: .visible, presenting: porEliminar) { d in
            Button("Eliminar", role: .destructive) { Task { await eliminar(d) } }
            Button("Cancelar", role: .cancel) { porEliminar = nil }
        } message: { Text($0.zona) }
        .alert("No se pudo eliminar", isPresented: .constant(error != nil)) {
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
