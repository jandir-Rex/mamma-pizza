import SwiftUI

struct BarraCarritoFlotante: View {
    @Environment(CarritoStore.self) private var carrito
    var onTap: () -> Void

    var body: some View {
        let visible = !carrito.items.isEmpty
        Group {
            if visible {
                Button(action: onTap) {
                    Image(systemName: "bag")
                        .font(.title2)
                        .foregroundStyle(AppColors.texto)
                        .frame(width: 54, height: 54)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(AppColors.hairline))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                        .overlay(alignment: .topTrailing) {
                            Text(carrito.cantidadItems > 99 ? "99+" : "\(carrito.cantidadItems)")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 21, minHeight: 21)
                                .background(AppColors.primary, in: Capsule())
                                .offset(x: 5, y: -5)
                        }
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityLabel("Carrito")
                .accessibilityValue("\(carrito.cantidadItems) productos")
            }
        }
        .animation(.smooth(duration: 0.3), value: visible)
    }
}

/// Botón de carrito simple del header (era `BotonCarrito` en tony_widgets.dart).
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
