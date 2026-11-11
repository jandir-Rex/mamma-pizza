import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var verPassword = false
    @State private var cargando = false
    @State private var error: String?
    @FocusState private var campo: Campo?

    private enum Campo { case email, password }

    private var valido: Bool { email.contains("@") && !password.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        MammaPizzaLogo()
                        Text("El sabor de la felicidad")
                            .font(.subheadline.italic())
                            .foregroundStyle(AppColors.gris)
                    }
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bienvenido de nuevo").font(.marca(.title))
                        Text("Ingresa para pedir tu pizza favorita")
                            .font(.subheadline).foregroundStyle(AppColors.gris)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        CampoFormulario(icono: "envelope") {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                                .focused($campo, equals: .email)
                                .onSubmit { campo = .password }
                        }

                        CampoFormulario(icono: "lock") {
                            Group {
                                if verPassword {
                                    TextField("Contraseña", text: $password)
                                } else {
                                    SecureField("Contraseña", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($campo, equals: .password)
                            .onSubmit { if valido { Task { await ingresar() } } }

                            Button { verPassword.toggle() } label: {
                                Image(systemName: verPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(AppColors.gris)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel(verPassword ? "Ocultar contraseña" : "Mostrar contraseña")
                        }
                    }

                    if let error { BannerError(error) }

                    Button { Task { await ingresar() } } label: {
                        HStack(spacing: 8) {
                            if cargando { ProgressView() }
                            Text("Ingresar")
                        }
                    }
                    .buttonStyle(.primario)
                    .disabled(!valido)

                    NavigationLink { RegistroView() } label: {
                        HStack(spacing: 4) {
                            Text("¿No tienes cuenta?").foregroundStyle(AppColors.gris)
                            Text("Regístrate").fontWeight(.semibold).foregroundStyle(AppColors.primary)
                        }
                        .font(.subheadline)
                        .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { FondoMarca() }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func ingresar() async {
        guard !cargando else { return }
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
