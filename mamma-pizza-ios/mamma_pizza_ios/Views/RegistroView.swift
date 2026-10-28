import SwiftUI

struct RegistroView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    
    @State private var nombre = ""
    @State private var email = ""
    @State private var password = ""
    @State private var telefono = ""
    @State private var ocultarPassword = true
    @State private var cargando = false
    @State private var errorMensaje: String?
    
    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    Text("Crea tu cuenta")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppColors.dark)
                    
                    Text("Únete a Mamma Pizza")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.gray)
                        .padding(.top, 2)
                        .padding(.bottom, 24)
                    
                    if let err = errorMensaje {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(AppColors.danger)
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.danger)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(red: 253/255, green: 236/255, blue: 234/255))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 16)
                    }
                    
                    // NOMBRE
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nombre completo").font(.caption).foregroundStyle(AppColors.gray)
                        TextField("", text: $nombre)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                    }
                    .padding(.bottom, 14)
                    
                    // EMAIL
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(.caption).foregroundStyle(AppColors.gray)
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                    }
                    .padding(.bottom, 14)
                    
                    // TELÉFONO
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Teléfono (Opcional)").font(.caption).foregroundStyle(AppColors.gray)
                        TextField("", text: $telefono)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                    }
                    .padding(.bottom, 14)
                    
                    // CONTRASEÑA
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Contraseña").font(.caption).foregroundStyle(AppColors.gray)
                        HStack {
                            if ocultarPassword {
                                SecureField("", text: $password)
                            } else {
                                TextField("", text: $password).autocapitalization(.none)
                            }
                            Button { ocultarPassword.toggle() } label: {
                                Image(systemName: ocultarPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(AppColors.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                    }
                    .padding(.bottom, 24)
                    
                    // BOTÓN REGISTRO
                    Button(action: manejarRegistro) {
                        HStack {
                            if cargando {
                                ProgressView().tint(.white).controlSize(.small)
                            } else {
                                Text("Registrarse").font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(cargando)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func manejarRegistro() {
        guard !nombre.isEmpty, email.contains("@"), !password.isEmpty else {
            errorMensaje = "Completa los campos obligatorios correctamente"
            return
        }
        
        cargando = true
        errorMensaje = nil
        
        Task {
            defer { cargando = false }
            do {
                let req = RegisterRequest(nombre: nombre, email: email, password: password, telefono: telefono.isEmpty ? nil : telefono)
                let res: AuthResponse = try await NetworkService.shared.post(endpoint: "/auth/registro", body: req)
                
                auth.guardarSesion(token: res.token, usuario: res.usuario)
                dismiss()
            } catch {
                errorMensaje = error.localizedDescription.replacingOccurrences(of: "Exception: ", with: "")
            }
        }
    }
}
