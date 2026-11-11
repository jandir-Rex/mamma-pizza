import SwiftUI

/// Píldora flotante: cantidad, acción y total.
struct BarraCarritoFlotante: View {
    @Environment(CarritoStore.self) private var carrito
    var onTap: () -> Void

    var body: some View {
        let visible = !carrito.items.isEmpty
        Group {
            if visible {
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        Text(carrito.cantidadItems > 99 ? "99+" : "\(carrito.cantidadItems)")
                            .font(.footnote.weight(.bold).monospacedDigit())
                            .frame(minWidth: 28, minHeight: 28)
                            .background(.white.opacity(0.22), in: Circle())
                        Text("Ver carrito").font(.headline)
                        Spacer()
                        Text(carrito.total.soles).font(.precio(.headline))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(AppColors.primary, in: Capsule())
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 14, y: 6)
                }
                .buttonStyle(.presion)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .sensoryFeedback(.impact(weight: .light), trigger: carrito.cantidadItems)
                .accessibilityLabel("Ver carrito")
                .accessibilityValue("\(carrito.cantidadItems) productos, \(carrito.total.soles)")
            }
        }
        .animation(.smooth(duration: 0.3), value: visible)
    }
}

/// Botón de carrito simple del header (sin cambios).
struct BotonCarrito: View {
    @Environment(CarritoStore.self) private var carrito
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "cart")
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 46, height: 46)
                .background(AppColors.surface, in: Circle())
                .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
                .overlay(alignment: .topTrailing) {
                    if carrito.cantidadItems > 0 {
                        Text("\(carrito.cantidadItems)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(AppColors.primary, in: Capsule())
                            .overlay(Capsule().stroke(AppColors.surface, lineWidth: 2))
                            .offset(x: 3, y: -3)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Carrito, \(carrito.cantidadItems) productos")
    }
}
