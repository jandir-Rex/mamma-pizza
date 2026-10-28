import SwiftUI
import Foundation

struct ProfileView: View {
    @State private var usuarioNombre = "Juan Pérez"
    @State private var usuarioEmail = "juan.perez@email.com"
    @State private var notificacionesActivas = true
    @State private var modoOscuro = false
    @State private var mostrarCerrarSesion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tarjeta de Usuario
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryLight.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(AppColors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(usuarioNombre)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.dark)
                                
                                Text(usuarioEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        
                        // Opciones
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mi Cuenta")
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ProfileOptionRow(icon: "mappin.and.ellipse", title: "Mis Direcciones")
                                Divider().background(AppColors.border)
                                ProfileOptionRow(icon: "clock.arrow.circlepath", title: "Historial de Pedidos")
                                Divider().background(AppColors.border)
                                ProfileOptionRow(icon: "creditcard", title: "Métodos de Pago")
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        
                        // Ajustes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ajustes de la App")
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                Toggle(isOn: $notificacionesActivas) {
                                    Label("Notificaciones Push", systemImage: "bell")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppColors.dark)
                                }
                                .padding()
                                .tint(AppColors.primary)
                                
                                Divider().background(AppColors.border)
                                
                                Toggle(isOn: $modoOscuro) {
                                    Label("Modo Oscuro", systemImage: "moon")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppColors.dark)
                                }
                                .padding()
                                .tint(AppColors.primary)
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        
                        // Botón de Salir
                        Button(role: .destructive) {
                            mostrarCerrarSesion = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar Sesión")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(AppColors.danger)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.danger.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil")
            .confirmationDialog("¿Seguro que deseas salir?", isPresented: $mostrarCerrarSesion, titleVisibility: .visible) {
                Button("Cerrar Sesión", role: .destructive) {}
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
}