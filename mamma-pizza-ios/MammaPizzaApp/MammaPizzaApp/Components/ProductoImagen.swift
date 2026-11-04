import SwiftUI

struct ProductoImagen: View {
    let url: String?
    var size: CGFloat = 84
    var radius: CGFloat = 14
    var icono: String = "fork.knife"

    private var fallback: some View {
        LinearGradient(colors: [Color(hex: 0xF7DDB4), Color(hex: 0xE9B56E)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(Image(systemName: icono)
                .font(.system(size: size * 0.45))
                .foregroundStyle(Color(hex: 0xC41E24)))
    }

    var body: some View {
        Group {
            if let url, let u = URL(string: url) {
                AsyncImage(url: u) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { fallback }          // cargando o error
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }
}
