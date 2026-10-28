import SwiftUI
import Foundation

struct CartItemRow: View {
    let item: ItemCarrito
    @Environment(CartManager.self) private var cart
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.producto.nombre)
                    .font(.headline)
                    .foregroundStyle(AppColors.dark)
                
                Text(item.variante.tamano)
                    .font(.caption)
                    .foregroundStyle(AppColors.gray)
                
                Text("S/.\(item.variante.precio, specifier: "%.2f") c/u")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.primaryLight)
            }
            
            Spacer()
            
            // CONTROLES DE CANTIDAD
            HStack(spacing: 10) {
                Button {
                    cart.cambiarCantidad(id: item.id, delta: -1)
                } label: {
                    Image(systemName: item.cantidad == 1 ? "trash" : "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(item.cantidad == 1 ? AppColors.danger : AppColors.gray)
                }
                
                Text("\(item.cantidad)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.dark)
                    .frame(minWidth: 20)
                
                Button {
                    cart.cambiarCantidad(id: item.id, delta: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .buttonStyle(.plain)
            
            Text("S/.\(item.subtotal, specifier: "%.2f")")
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.dark)
                .frame(width: 65, alignment: .trailing)
        }
    }
}