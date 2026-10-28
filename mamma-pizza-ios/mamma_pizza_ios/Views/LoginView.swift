import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var ocultarPassword = true
    @State private var cargando = false
    @State private var errorMensaje: String?
    @State private var irARegistro = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        
                        // LOGO
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.primaryLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 84, height: 84)
                                .shadow(color: AppColors.primary.opacity(0.25), radius: 20, x: 0, y: 8)
                            
                            Text("🍕")
                                .font(.system(size: 40))
                        }
                        
                        // TÍTULOS
                        Text("Mamma Pizza")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(AppColors.dark)
                            .padding(.top, 20)
                        
                        Text("El sabor de la felicidad")
                            .font(.system(size: 13, weight: .regular))
                            .italic()
                            .foregroundStyle(AppColors.gray)
                            .padding(.top, 2)
                        
                        Spacer(minLength: 36)
                        
                        // ALERTA DE ERROR
                        if let err = errorMensaje {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(AppColors.danger)
                                    .font(.system(size: 18))
                                
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.danger)
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 253/255, green: 236/255, blue: 234/255))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.danger.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // INPUT EMAIL
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(AppColors.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(AppColors.gray)
                                    .font(.system(size: 18))
                                
                                TextField("", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundStyle(AppColors.dark)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 14)
                        
                        // INPUT CONTRASEÑA
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contraseña")
                                .font(.caption)
                                .foregroundStyle(AppColors.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundStyle(AppColors.gray)
                                    .font(.system(size: 18))
                                
                                if ocultarPassword {
                                    SecureField("", text: $password)
                                        .foregroundStyle(AppColors.dark)
                                } else {
                                    TextField("", text: $password)
                                        .autocapitalization(.none)
                                        .foregroundStyle(AppColors.dark)
                                }
                                
                                Button {
                                    ocultarPassword.toggle()
                                } label: {
                                    Image(systemName: ocultarPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(AppColors.gray)
                                        .font(.system(size: 18))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 28)
                        
                        // BOTÓN INGRESAR
                        Button(action: manejarLogin) {
                            HStack {
                                if cargando {
                                    ProgressView()
                                        .tint(.white)
                                        .controlSize(.small)
                                } else {
                                    Text("Ingresar")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(cargando)
                        .padding(.bottom, 18)
                        
                        // IR A REGISTRO
                        HStack(spacing: 4) {
                            Text("¿No tienes cuenta?")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.gray)
                            
                            Button("Regístrate") {
                                irARegistro = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                }
            }
            .navigationDestination(isPresented: $irARegistro) {
                RegistroView()
            }
        }
    }
    
    private func manejarLogin() {
        guard email.contains("@") else {
            withAnimation { errorMensaje = "Ingresa un email válido" }
            return
        }
        guard !password.isEmpty else {
            withAnimation { errorMensaje = "Ingresa tu contraseña" }
            return
        }
        
        withAnimation {
            cargando = true
            errorMensaje = nil
        }
        
        Task {
            defer { cargando = false }
            do {
                let req = LoginRequest(email: email.trimmingCharacters(in: .whitespaces), password: password)
                let res: AuthResponse = try await NetworkService.shared.post(endpoint: "/auth/login", body: req)
                
                auth.guardarSesion(token: res.token, usuario: res.usuario)
                dismiss()
            } catch {
                withAnimation {
                    errorMensaje = error.localizedDescription.replacingOccurrences(of: "Exception: ", with: "")
                }
            }
        }
    }
}
