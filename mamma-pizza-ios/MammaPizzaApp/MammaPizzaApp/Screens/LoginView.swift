import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var cargando = false
    @State private var error: String?
    @FocusState private var campo: Campo?

    private enum Campo { case email, password }

    private var puedeEnviar: Bool {
        email.contains("@") && !password.isEmpty && !cargando
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 6) {
                        MammaPizzaLogo()
                        Text("El sabor de la felicidad")
                            .font(.footnote.italic())
                            .foregroundStyle(AppColors.gris)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle")
                            .foregroundStyle(AppColors.danger)
                            .font(.footnote)
                    }
                }

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($campo, equals: .email)
                        .onSubmit { campo = .password }

                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($campo, equals: .password)
                        .onSubmit { if puedeEnviar { Task { await ingresar() } } }
                }

                Section {
                    Button {
                        Task { await ingresar() }
                    } label: {
                        HStack {
                            if cargando { ProgressView() }
                            Text("Ingresar").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!puedeEnviar)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink("¿No tienes cuenta? Regístrate") { RegistroView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func ingresar() async {
        campo = nil
        cargando = true
        error = nil
        defer { cargando = false }
        do {
            try await auth.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
