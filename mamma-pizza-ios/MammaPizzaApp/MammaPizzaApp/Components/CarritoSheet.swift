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
            .background(AppColors.bg)
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
            Section {
                ForEach(carrito.items) { item in
                    FilaCarrito(item: item)
                        .swipeActions(edge: .trailing) {
                            Button("Quitar", role: .destructive) {
                                withAnimation { carrito.quitar(id: item.id) }
                            }
                        }
                }
            }
            Section("Resumen") {
                LabeledContent("Subtotal", value: carrito.total.soles)
                LabeledContent("Delivery", value: "Al pagar")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var barraTotal: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(carrito.total.soles)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.primary)
            }
            Button {
                dismiss()
                onContinuar()
            } label: {
                Text("Continuar al pago").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColors.primary)
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
            ProductoImagen(url: item.producto.imagenUrl, size: 64, radius: 12,
                           icono: iconoCategoria(item.producto.categoriaNombre))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.producto.nombre)
                    .font(.subheadline.weight(.semibold))
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
                HStack {
                    Text(item.subtotal.soles)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                    controles
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// Botones de 44 pt (mínimo HIG). Con cantidad 1 el "−" se convierte en papelera.
    private var controles: some View {
        HStack(spacing: 0) {
            Button {
                carrito.cambiarCantidad(id: item.id, delta: -1)
            } label: {
                Image(systemName: item.cantidad == 1 ? "trash" : "minus")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(item.cantidad == 1 ? "Quitar producto" : "Disminuir cantidad")

            Text("\(item.cantidad)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .frame(minWidth: 22)

            Button {
                carrito.cambiarCantidad(id: item.id, delta: 1)
            } label: {
                Image(systemName: "plus").frame(width: 44, height: 44)
            }
            .disabled(item.cantidad >= CarritoStore.maxPorItem)
            .accessibilityLabel("Aumentar cantidad")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(AppColors.texto)
    }
}
