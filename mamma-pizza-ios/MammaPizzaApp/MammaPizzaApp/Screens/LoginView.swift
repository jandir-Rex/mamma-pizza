import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth

    var comoHoja = false
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var verPassword = false
    @State private var cargando = false
    @State private var error: String?
    @State private var aparecio = false

    @FocusState private var campo: Campo?

    private enum Campo { case email, password }

    private var emailValido: Bool {
        let t = email.trimmingCharacters(in: .whitespaces)
        return t.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
    }

    private var valido: Bool { emailValido && !password.isEmpty }

    /// Se carga una sola vez al crear la vista, no en cada redibujado.
    private let logoImagen: UIImage? = {
        guard let path = Bundle.main.path(forResource: "brand_logo", ofType: "jpeg") else { return nil }
        return UIImage(contentsOfFile: path)
    }()

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        cabecera
                            .opacity(aparecio ? 1 : 0)
                            .offset(y: aparecio ? 0 : -20)

                        Spacer(minLength: 28)

                        panelCristal
                            .opacity(aparecio ? 1 : 0)
                            .offset(y: aparecio ? 0 : 60)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                    .frame(minHeight: geo.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background {
                ZStack {
                    LoopingVideoBackground(name: "ad6")
                    Color.black.opacity(0.12)
                    LinearGradient(
                        colors: [.black.opacity(0.55), .clear, .black.opacity(0.60)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if comoHoja {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cerrar") { dismiss() }
                            .foregroundStyle(.white)
                    }
                }
            }
            .onChange(of: auth.usuario != nil) { _, hay in
                if hay && comoHoja { dismiss() }
            }
            .interactiveDismissDisabled(cargando)
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.82).delay(0.1)) {
                    aparecio = true
                }
            }
        }
    }

    private var cabecera: some View {
        VStack(spacing: 10) {
            Group {
                if let img = logoImagen {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppColors.kraft)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.marcaDegradado)
                }
            }
            .frame(width: 78, height: 78)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    LinearGradient(colors: [AppColors.mostaza, .white.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 2
                )
            )
            .shadow(color: AppColors.mostaza.opacity(0.45), radius: 18, y: 4)

            Text("MammaPizza")
                .font(.system(.largeTitle, design: .serif, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 2)

            Text("PIZZA HOUSE")
                .font(.caption2.weight(.bold))
                .tracking(4)
                .foregroundStyle(AppColors.mostaza)

            Text("El sabor de la felicidad")
                .font(.subheadline.italic())
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
        }
        .padding(.top, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mamma Pizza")
    }

    private var panelCristal: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bienvenido de nuevo")
                    .font(.marca(.title))
                    .foregroundStyle(.white)

                Text(comoHoja ? "Inicia sesión para completar tu pedido"
                              : "Ingresa para pedir tu pizza favorita")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                campoCristal(icono: "envelope", activo: campo == .email) {
                    TextField("", text: $email,
                              prompt: Text("Email").foregroundStyle(.white.opacity(0.5)))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($campo, equals: .email)
                        .onSubmit { campo = .password }
                }

                campoCristal(icono: "lock", activo: campo == .password) {
                    Group {
                        if verPassword {
                            TextField("", text: $password,
                                      prompt: Text("Contraseña").foregroundStyle(.white.opacity(0.5)))
                        } else {
                            SecureField("", text: $password,
                                        prompt: Text("Contraseña").foregroundStyle(.white.opacity(0.5)))
                        }
                    }
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($campo, equals: .password)
                    .onSubmit {
                        if valido { Task { await ingresar() } }
                    }

                    Button { verPassword.toggle() } label: {
                        Image(systemName: verPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(verPassword ? "Ocultar contraseña" : "Mostrar contraseña")
                }
            }

            if let error { BannerError(error) }

            Button { Task { await ingresar() } } label: {
                HStack(spacing: 8) {
                    if cargando { ProgressView().tint(AppColors.cacao) }
                    Text("Ingresar")
                        .font(.headline)
                }
                .foregroundStyle(AppColors.cacao)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    LinearGradient(colors: [AppColors.mostaza, AppColors.kraft],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: AppColors.mostaza.opacity(valido ? 0.5 : 0), radius: 14, y: 6)
                .opacity(valido ? 1 : 0.55)
            }
            .disabled(!valido || cargando)
            .animation(.easeOut(duration: 0.25), value: valido)
            .animation(.easeOut(duration: 0.2), value: cargando)

            NavigationLink { RegistroView() } label: {
                HStack(spacing: 4) {
                    Text("¿No tienes cuenta?")
                        .foregroundStyle(.white.opacity(0.75))

                    Text("Regístrate")
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.mostaza)
                }
                .font(.subheadline)
                .frame(minHeight: 44)
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.white.opacity(0.06))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.65), .white.opacity(0.08), .white.opacity(0.30)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.2
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }

    private func campoCristal<C: View>(icono: String, activo: Bool,
                                       @ViewBuilder _ contenido: () -> C) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .foregroundStyle(activo ? AppColors.mostaza : .white.opacity(0.7))
                .frame(width: 22)
            contenido()
        }
        .foregroundStyle(.white)
        .tint(AppColors.mostaza)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(activo ? 0.16 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(activo ? AppColors.mostaza.opacity(0.9) : .white.opacity(0.22),
                        lineWidth: activo ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: activo)
    }

    private func ingresar() async {
        guard !cargando else { return }

        campo = nil
        cargando = true
        error = nil

        defer { cargando = false }

        do {
            try await auth.login(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
