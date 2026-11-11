import SwiftUI

struct TarjetaProducto: View {
    let producto: Producto
    var agotado: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: 14) {
                ProductoImagen(url: producto.imagenUrl, size: 92, radius: 16,
                               icono: iconoCategoria(producto.categoriaNombre))

                VStack(alignment: .leading, spacing: 4) {
                    Text(producto.nombre)
                        .font(.headline)
                        .foregroundStyle(AppColors.texto)
                        .lineLimit(1)
                    Text(descripcion)
                        .font(.footnote)
                        .foregroundStyle(AppColors.gris)
                        .lineLimit(2)

                    Spacer(minLength: 6)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Desde").font(.caption2).foregroundStyle(AppColors.gris)
                            Text(producto.precioDesde.soles)
                                .font(.precio(.headline))
                                .foregroundStyle(AppColors.primary)
                        }
                        Spacer()
                        if agotado {
                            Text("Agotado")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.danger)
                        } else {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(AppColors.primary, in: Circle())
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            }
            .tarjeta(padding: 10, radio: 20)
            .opacity(agotado ? 0.6 : 1)
        }
        .buttonStyle(.presion)
        .accessibilityElement(children: .combine)
        .accessibilityHint(agotado ? "Producto agotado" : "Ver opciones del producto")
    }

    private var descripcion: String {
        let d = (producto.descripcion ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return d.isEmpty ? "Deliciosa opción de la casa" : d
    }
}
