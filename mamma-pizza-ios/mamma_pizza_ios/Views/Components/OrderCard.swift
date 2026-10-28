import SwiftUI
import Foundation

struct OrderCard: View {
    let pedido: Pedido
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pedido #\(pedido.codigo)")
                        .font(.headline)
                        .foregroundStyle(AppColors.dark)
                    
                    Text(pedido.fechaFormateada)
                        .font(.caption)
                        .foregroundStyle(AppColors.gray)
                }
                
                Spacer()
                
                // Usamos el componente que creaste
                BadgeEstadoPedido(estado: pedido.estado)
            }
            
            Divider().background(AppColors.border)
            
            HStack {
                Text("\(pedido.items.count) productos")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.gray)
                
                Spacer()
                
                Text("S/.\(pedido.total, specifier: "%.2f")")
                    .font(.headline)
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
}