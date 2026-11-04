import SwiftUI

struct TarjetaProducto: View {
    let producto: Producto
    var agotado: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: 12) {
                ProductoImagen(url: producto.imagenUrl, size: 84, radius: 14,
                               icono: iconoCategoria(producto.categoriaNombre))

                VStack(alignment: .leading, spacing: 3) {
                    Text(producto.nombre)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.texto)
                        .lineLimit(1)
                    Text(descripcion)
                        .font(.caption)
                        .foregroundStyle(AppColors.gris)
                        .lineLimit(2)
                    Spacer(minLength: 4)

                    if agotado {
                        Text("Agotado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.danger)
                    } else {
                        HStack {
                            Text("Desde \(producto.precioDesde.soles)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppColors.texto)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(AppColors.primary, in: Circle())
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
            .opacity(agotado ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(agotado ? "Producto agotado" : "Ver opciones del producto")
    }

    private var descripcion: String {
        let d = (producto.descripcion ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return d.isEmpty ? "Deliciosa opción de la casa" : d
    }
}
