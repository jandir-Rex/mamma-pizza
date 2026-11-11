import SwiftUI

struct PerfilView: View {
    @Environment(AuthStore.self) private var auth
    @State private var editando = false
    @State private var confirmandoLogout = false

    private var inicial: String { String((auth.usuario?.nombre ?? "?").prefix(1)).uppercased() }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Text(inicial)
                            .font(.title2.weight(.bold)).foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(AppColors.primary, in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.usuario?.nombre ?? "").font(.headline)
                            Text(auth.usuario?.email ?? "").font(.subheadline).foregroundStyle(AppColors.gris)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }

                Section("Cuenta") {
                    NavigationLink { DireccionesView() } label: {
                        Label("Mis direcciones", systemImage: "mappin.and.ellipse")
                    }
                    Button { editando = true } label: {
                        Label("Editar nombre", systemImage: "person.text.rectangle")
                    }
                    .foregroundStyle(AppColors.texto)
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) { confirmandoLogout = true }
                        .frame(maxWidth: .infinity)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.bg)
            .navigationTitle("Mi perfil")
            .conCarritoFlotante()
            .confirmationDialog("¿Cerrar sesión?", isPresented: $confirmandoLogout, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive) { auth.logout() }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $editando) { EditarNombreSheet() }
        }
    }
}

private struct EditarNombreSheet: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var nombre = ""
    @State private var error: String?
    @State private var guardando = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre completo", text: $nombre).textContentType(.name)
                } footer: {
                    if let error { Text(error).foregroundStyle(AppColors.danger) }
                }
            }
            .navigationTitle("Editar nombre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await guardar() } }.disabled(guardando)
                }
            }
            .onAppear { nombre = auth.usuario?.nombre ?? "" }
        }
        .presentationDetents([.medium])
    }

    private func guardar() async {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)
        guard limpio.count >= 2 else { error = "Nombre muy corto"; return }
        guardando = true
        defer { guardando = false }
        do {
            try await auth.actualizarPerfil(nombre: limpio)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
