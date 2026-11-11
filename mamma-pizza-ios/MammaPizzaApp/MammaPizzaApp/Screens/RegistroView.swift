import SwiftUI

struct RegistroView: View {
    @Environment(AuthStore.self) private var auth
    @State private var nombre = ""
    @State private var email = ""
    @State private var telefono = ""
    @State private var password = ""
    @State private var cargando = false
    @State private var error: String?
    @FocusState private var campo: Campo?

    private enum Campo { case nombre, email, telefono, password }

    private var valido: Bool {
        nombre.trimmingCharacters(in: .whitespaces).count >= 2
            && email.contains("@")
            && password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Únete a MammaPizza").font(.marca(.title))
                    Text("Crea tu cuenta y pide en segundos")
                        .font(.subheadline).foregroundStyle(AppColors.gris)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    CampoFormulario(icono: "person") {
                        TextField("Nombre completo", text: $nombre)
                            .textContentType(.name)
                            .submitLabel(.next)
                            .focused($campo, equals: .nombre)
                            .onSubmit { campo = .email }
                    }
                    CampoFormulario(icono: "envelope") {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($campo, equals: .email)
                            .onSubmit { campo = .telefono }
                    }
                    CampoFormulario(icono: "phone") {
                        TextField("Teléfono (opcional)", text: $telefono)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .focused($campo, equals: .telefono)
                    }
                    CampoFormulario(icono: "lock") {
                        SecureField("Contraseña", text: $password)
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .focused($campo, equals: .password)
                            .onSubmit { if valido { Task { await registrar() } } }
                    }

                    Label("Mínimo 6 caracteres",
                          systemImage: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                        .font(.footnote)
                        .foregroundStyle(password.count >= 6 ? AppColors.success : AppColors.gris)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                        .animation(.snappy, value: password.count >= 6)
                }

                if let error { BannerError(error) }

                Button { Task { await registrar() } } label: {
                    HStack(spacing: 8) {
                        if cargando { ProgressView() }
                        Text("Crear cuenta")
                    }
                }
                .buttonStyle(.primario)
                .disabled(!valido)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { FondoMarca() }
        .navigationTitle("Crear cuenta")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func registrar() async {
        guard !cargando else { return }
        campo = nil
        cargando = true
        error = nil
        defer { cargando = false }
        do {
            try await auth.registro(nombre: nombre.trimmingCharacters(in: .whitespaces),
                                    email: email.trimmingCharacters(in: .whitespaces),
                                    password: password,
                                    telefono: telefono.trimmingCharacters(in: .whitespaces))
        } catch {
            self.error = error.localizedDescription
        }
    }
}
