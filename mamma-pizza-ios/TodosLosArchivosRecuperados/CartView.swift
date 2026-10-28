import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/jandir/Documents/mamma-pizza/mamma-pizza-app-cliente-ios/MammaPizzaClient/MammaPizzaClient/Views/CartView.swift", line: 1)
import SwiftUI

struct CartView: View {
    @Environment(CartManager.self) private var cart
    
    @State private var enviandoPedido = false
    @State private var mostrarAlertaExito = false
    @State private var codigoPedido = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if cart.items.isEmpty {
                    ContentUnavailableView(
                        __designTimeString("#2601_0", fallback: "Tu carrito está vacío"),
                        systemImage: __designTimeString("#2601_1", fallback: "cart"),
                        description: Text(__designTimeString("#2601_2", fallback: "Agrega unas deliciosas pizzas desde el menú para empezar."))
                    )
                } else {
                    VStack {
                        List {
                            ForEach(cart.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: __designTimeInteger("#2601_3", fallback: 4)) {
                                        Text(item.producto.nombre)
                                            .font(.headline)
                                        Text("Tamaño: \(item.variante.tamano)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: __designTimeInteger("#2601_4", fallback: 12)) {
                                        Button {
                                            cart.cambiarCantidad(id: item.id, delta: __designTimeInteger("#2601_5", fallback: -1))
                                        } label: {
                                            Image(systemName: __designTimeString("#2601_6", fallback: "minus.circle"))
                                        }
                                        
                                        Text("\(item.cantidad)")
                                            .font(.subheadline.bold())
                                        
                                        Button {
                                            cart.cambiarCantidad(id: item.id, delta: __designTimeInteger("#2601_7", fallback: 1))
                                        } label: {
                                            Image(systemName: __designTimeString("#2601_8", fallback: "plus.circle"))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.orange)
                                    
                                    Text("S/.\(item.subtotal, specifier: __designTimeString("#2601_9", fallback: "%.2f"))")
                                        .font(.subheadline.bold())
                                        .frame(width: __designTimeInteger("#2601_10", fallback: 70), alignment: .trailing)
                                }
                            }
                            .onDelete(perform: cart.quitar)
                        }
                        .listStyle(.insetGrouped)
                        
                        VStack(spacing: __designTimeInteger("#2601_11", fallback: 12)) {
                            HStack {
                                Text(__designTimeString("#2601_12", fallback: "Total:"))
                                    .font(.title2.bold())
                                Spacer()
                                Text("S/.\(cart.total, specifier: __designTimeString("#2601_13", fallback: "%.2f"))")
                                    .font(.title2.bold())
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal)
                            
                            Button(action: procesarPedido) {
                                Text(__designTimeString("#2601_14", fallback: "Confirmar Pedido"))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            .disabled(enviandoPedido)
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                    }
                }
            }
            .navigationTitle(__designTimeString("#2601_15", fallback: "Mi Carrito 🛒"))
            .alert(__designTimeString("#2601_16", fallback: "¡Pedido Realizado! 🍕"), isPresented: $mostrarAlertaExito) {
                Button(__designTimeString("#2601_17", fallback: "Aceptar"), role: .cancel) { }
            } message: {
                Text("Tu código de pedido es: \(codigoPedido). Puedes ver el estado en la pestaña de Pedidos.")
            }
            .overlay {
                if enviandoPedido {
                    ProgressView(__designTimeString("#2601_18", fallback: "Procesando tu pedido..."))
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: __designTimeInteger("#2601_19", fallback: 12)))
                }
            }
        }
    }
    
    private func procesarPedido() {
        Task {
            enviandoPedido = __designTimeBoolean("#2601_20", fallback: true)
            defer { enviandoPedido = __designTimeBoolean("#2601_21", fallback: false) }
            
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
                self.mostrarAlertaExito = __designTimeBoolean("#2601_22", fallback: true)
                cart.vaciar()
            } catch {
                print("Error al crear pedido: \(error)")
            }
        }
    }
}

#Preview {
    CartView()
        .environment(CartManager())
}
