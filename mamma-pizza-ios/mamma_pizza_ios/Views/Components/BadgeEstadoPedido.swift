import SwiftUI
import Foundation

struct BadgeEstadoPedido: View {
    let estado: String
    
    var body: some View {
        let color = EstadoPedidoUI.color(para: estado)
        
        Text(EstadoPedidoUI.etiqueta(para: estado))
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}