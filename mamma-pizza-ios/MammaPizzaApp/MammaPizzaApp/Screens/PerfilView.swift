import SwiftUI

struct PerfilView: View {
    @Environment(AuthStore.self) private var auth
    @State private var editando = false
    @State private var confirmandoLogout = false

    private var inicial: String {
        String((auth.usuario?.nombre ?? "?").prefix(1)).uppercased()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Text(inicial)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(AppColors.kraft)
                            .frame(width: 88, height: 88)
                            .background(AppColors.marcaDegradado, in: Circle())
                            .accessibilityHidden(true)

                        VStack(spacing: 2) {
                            Text(auth.usuario?.nombre ?? "")
                                .font(.title3.weight(.bold))

                            Text(auth.usuario?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.gris)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .combine)
                }

                Section("Cuenta") {
                    NavigationLink {
                        DireccionesView()
                    } label: {
                        FilaAjuste(
                            "Mis direcciones",
                            icono: "mappin.and.ellipse",
                            color: AppColors.primary
                        )
                    }

                    Button { editando = true } label: {
                        FilaAjuste(
                            "Editar nombre",
                            icono: "person.text.rectangle",
                            color: AppColors.info
                        )
                    }
                    .foregroundStyle(AppColors.texto)
                }

                Section {
                    Button(role: .destructive) {
                        confirmandoLogout = true
                    } label: {
                        Text("Cerrar sesión")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .fondoApp()
            .navigationTitle("Mi perfil")
            .conCarritoFlotante()
            .confirmationDialog(
                "¿Cerrar sesión?",
                isPresented: $confirmandoLogout,
                titleVisibility: .visible
            ) {
                Button("Cerrar sesión", role: .destructive) {
                    auth.logout()
                }

                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $editando) {
                EditarNombreSheet()
            }
        }
        // NUEVO: requiere sesión para mostrar el perfil
        .sesionRequerida(
            titulo: "Tu perfil",
            mensaje: "Inicia sesión para ver tus datos y direcciones",
            icono: "person.crop.circle"
        )
    }
}


/// Fila estilo Ajustes de iOS: ícono blanco sobre cuadrado de color.

private struct FilaAjuste: View {
    let titulo: String
    let icono: String
    let color: Color

    init(_ titulo: String, icono: String, color: Color) {
        self.titulo = titulo
        self.icono = icono
        self.color = color
    }

    var body: some View {
        Label {
            Text(titulo)
        } icon: {
            Image(systemName: icono)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    TextField("Nombre completo", text: $nombre)
                        .textContentType(.name)
                } footer: {
                    if let error {
                        Text(error)
                            .foregroundStyle(AppColors.danger)
                    }
                }
            }
            .navigationTitle("Editar nombre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await guardar() }
                    }
                    .disabled(guardando)
                }
            }
            .onAppear {
                nombre = auth.usuario?.nombre ?? ""
            }
        }
        .presentationDetents([.medium])
    }

    private func guardar() async {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)

        guard limpio.count >= 2 else {
            error = "Nombre muy corto"
            return
        }

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
