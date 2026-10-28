import SwiftUI
import Foundation

struct ProductCard: View {
    let producto: Producto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let urlString = producto.imagenUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(height: 130)
                    .clipped()
                } else {
                    placeholderImage
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(producto.nombre)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(AppColors.dark)
                
                if let desc = producto.descripcion {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(AppColors.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    if let precio = producto.variantes.first?.precio {
                        Text("S/.\(precio, specifier: "%.2f")")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(AppColors.bg)
            .frame(height: 130)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.gray.opacity(0.5))
            }
    }
}