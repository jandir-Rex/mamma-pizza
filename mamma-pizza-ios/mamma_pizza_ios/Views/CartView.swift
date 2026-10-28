import SwiftUI
import Foundation

struct CartView: View {
    @Environment(CartManager.self) private var cart
    
    @State private var enviandoPedido = false
    @State private var mostrarAlertaExito = false
    @State private var codigoPedido = ""
    @State private var notasPedido = ""
    
    // Costo de envío ficticio o configurable
    private let costoEnvio: Double = 5.00
    
    var totalConEnvio: Double {
        cart.total > 0 ? cart.total + costoEnvio : 0.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                
                Group {
                    if cart.items.isEmpty {
                        ContentUnavailableView(
                            "Tu carrito está vacío",
                            systemImage: "bag",
                            description: Text("Explora nuestro menú y agrega tus productos favoritos.")
                        )
                    } else {
                        VStack(spacing: 0) {
                            ScrollView {
                                VStack(spacing: 16) {
                                    // LISTA DE PRODUCTOS EN EL CARRITO
                                    VStack(spacing: 12) {
                                        ForEach(cart.items) { item in
                                            CartItemRow(item: item)
                                            
                                            if item.id != cart.items.last?.id {
                                                Divider().background(AppColors.border)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                    
                                    // NOTAS ADICIONALES
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Instrucciones especiales", systemImage: "square.and.pencil")
                                            .font(.caption.bold())
                                            .foregroundStyle(AppColors.gray)
                                        
                                        TextField("Ej. Sin cebolla, timbre averiado...", text: $notasPedido)
                                            .font(.subheadline)
                                            .padding(12)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(AppColors.border, lineWidth: 1)
                                            )
                                    }
                                    
                                    // RESUMEN DE PAGO
                                    VStack(spacing: 12) {
                                        Text("Resumen del Pedido")
                                            .font(.headline)
                                            .foregroundStyle(AppColors.dark)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Divider().background(AppColors.border)
                                        
                                        HStack {
                                            Text("Subtotal")
                                                .foregroundStyle(AppColors.gray)
                                            Spacer()
                                            Text("S/.\(cart.total, specifier: "%.2f")")
                                                .foregroundStyle(AppColors.dark)
                                        }
                                        .font(.subheadline)
                                        
                                        HStack {
                                            Text("Costo de delivery")
                                                .foregroundStyle(AppColors.gray)
                                            Spacer()
                                            Text("S/.\(costoEnvio, specifier: "%.2f")")
                                                .foregroundStyle(AppColors.dark)
                                        }
                                        .font(.subheadline)
                                        
                                        Divider().background(AppColors.border)
                                        
                                        HStack {
                                            Text("Total a pagar")
                                                .font(.headline)
                                                .foregroundStyle(AppColors.dark)
                                            Spacer()
                                            Text("S/.\(totalConEnvio, specifier: "%.2f")")
                                                .font(.title3.bold())
                                                .foregroundStyle(AppColors.primary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                                .padding()
                            }
                            
                            // BARRA INFERIOR DE ACCIÓN
                            VStack {
                                Button(action: procesarPedido) {
                                    HStack {
                                        Image(systemName: "checkmark.shield.fill")
                                        Text("Confirmar Pedido")
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .disabled(enviandoPedido)
                            }
                            .padding()
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(AppColors.border),
                                alignment: .top
                            )
                        }
                    }
                }
            }
            .navigationTitle("Carrito")
            .alert("¡Pedido Realizado!", isPresented: $mostrarAlertaExito) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text("Tu pedido fue procesado exitosamente con el código: \(codigoPedido).")
            }
            .overlay {
                if enviandoPedido {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Enviando pedido...")
                            .padding(20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }
    
    private func procesarPedido() {
        Task {
            enviandoPedido = true
            defer { enviandoPedido = false }
            
            let itemsRequest = cart.items.map { item in
                CrearPedidoItemRequest(
                    productoVarianteId: item.variante.id,
                    cantidad: item.cantidad,
                    notas: item.notas
                )
            }
            
            let requestBody = CrearPedidoRequest(
                canal: .delivery,
                direccionId: nil,
                mesaId: nil,
                items: itemsRequest
            )
            
            do {
                let respuesta: PedidoCreadoResponse = try await NetworkService.shared.crearPedido(req: requestBody)
                self.codigoPedido = respuesta.codigo
                self.mostrarAlertaExito = true
                cart.vaciar()
            } catch {
                print("Error al crear pedido: \(error)")
            }
        }
    }
}