import SwiftUI

struct CarritoSheet: View {
    @Environment(CarritoStore.self) private var carrito
    @Environment(\.dismiss) private var dismiss
    @State private var confirmandoVaciar = false

    /// Se llama después de cerrar la hoja; el padre empuja Checkout.
    var onContinuar: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if carrito.items.isEmpty {
                    ContentUnavailableView("Tu carrito está vacío",
                                           systemImage: "bag",
                                           description: Text("Agrega una pizza para comenzar"))
                } else {
                    lista
                }
            }
            .fondoApp()
            .navigationTitle("Mi carrito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !carrito.items.isEmpty {
                        Button("Vaciar", role: .destructive) { confirmandoVaciar = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .confirmationDialog("Vaciar carrito", isPresented: $confirmandoVaciar, titleVisibility: .visible) {
                Button("Vaciar carrito", role: .destructive) { carrito.vaciar() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Quieres quitar todos los productos de tu pedido?")
            }
            .safeAreaInset(edge: .bottom) {
                if !carrito.items.isEmpty { barraTotal }
            }
        }
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.bg)
    }

    private var lista: some View {
        List {
            ForEach(carrito.items) { item in
                FilaCarrito(item: item)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button("Quitar", role: .destructive) {
                            withAnimation { carrito.quitar(id: item.id) }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var barraTotal: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Subtotal").font(.subheadline).foregroundStyle(AppColors.gris)
                    Text("Delivery: al pagar").font(.caption).foregroundStyle(AppColors.gris)
                }
                Spacer()
                Text(carrito.total.soles)
                    .font(.precio(.title))
                    .foregroundStyle(AppColors.primary)
                    .contentTransition(.numericText(value: carrito.total))
                    .animation(.snappy, value: carrito.total)
            }
            Button {
                dismiss()
                onContinuar()
            } label: {
                Label("Continuar al pago", systemImage: "arrow.right")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.primario)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

private struct FilaCarrito: View {
    @Environment(CarritoStore.self) private var carrito
    let item: ItemCarrito

    private var detalle: String {
        let tamano = item.variante.tamano.capitalizadoLimpio
        let extras = item.agregados.map(\.nombre).joined(separator: ", ")
        return extras.isEmpty ? tamano : "\(tamano) · \(extras)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductoImagen(url: item.producto.imagenUrl, size: 72, radius: 14,
                           icono: iconoCategoria(item.producto.categoriaNombre))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.producto.nombre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.texto)
                    .lineLimit(1)
                Text(detalle)
                    .font(.caption)
                    .foregroundStyle(AppColors.gris)
                    .lineLimit(2)
                if !item.notas.isEmpty {
                    Text("“\(item.notas)”")
                        .font(.caption2).italic()
                        .foregroundStyle(AppColors.gris)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                HStack {
                    Text(item.subtotal.soles)
                        .font(.precio(.subheadline))
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                    SelectorCantidad(cantidad: item.cantidad,
                                     maximo: CarritoStore.maxPorItem,
                                     minimoEliminar: true,
                                     onMenos: { withAnimation { carrito.cambiarCantidad(id: item.id, delta: -1) } },
                                     onMas: { carrito.cambiarCantidad(id: item.id, delta: 1) })
                }
            }
        }
        .tarjeta(padding: 12, radio: 20)
    }
}
