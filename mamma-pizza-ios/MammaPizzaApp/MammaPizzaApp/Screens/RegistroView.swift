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
        Form {
            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(AppColors.danger)
                        .font(.footnote)
                }
            }

            Section {
                TextField("Nombre completo", text: $nombre)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($campo, equals: .nombre)
                    .onSubmit { campo = .email }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($campo, equals: .email)
                    .onSubmit { campo = .telefono }

                TextField("Teléfono (opcional)", text: $telefono)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .focused($campo, equals: .telefono)

                SecureField("Contraseña", text: $password)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .focused($campo, equals: .password)
                    .onSubmit { if valido { Task { await registrar() } } }
            } footer: {
                Text("La contraseña debe tener al menos 6 caracteres.")
            }

            Section {
                Button {
                    Task { await registrar() }
                } label: {
                    HStack {
                        if cargando { ProgressView() }
                        Text("Crear cuenta").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!valido || cargando)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("Crear cuenta")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func registrar() async {
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
