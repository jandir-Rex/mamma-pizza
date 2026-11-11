import SwiftUI

struct SeguimientoPedidoView: View {
    let pedido: Pedido
    var etaMinutos: Int? = nil
    var onVerDetalles: (() -> Void)? = nil

    private var pasos: [String] {
        pedido.esDelivery ? ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO", "ENTREGADO"]
                          : ["CONFIRMADO", "EN_PREPARACION", "ENTREGADO"]
    }
    private var cancelado: Bool { pedido.estado == "CANCELADO" }
    private var entregado: Bool { pedido.estado == "ENTREGADO" }
    private var indice: Int { pasos.firstIndex(of: pedido.estado) ?? -1 }
    private var colorEstado: Color { cancelado ? AppColors.danger : entregado ? AppColors.success : AppColors.primary }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            cabecera

            if !cancelado {
                PasosPedidoView(pasos: pasos, indice: indice, creado: pedido.createdAt)
                    .tarjeta()
            }

            if pedido.esDelivery && pedido.estado == "EN_CAMINO" {
                CodigoEntregaCard(codigo: pedido.codigoConfirmacion, estado: pedido.estado,
                                  canal: pedido.canal, intentosFallidos: pedido.intentosCodigoFallidos)
            }

            if entregado, pedido.confirmadoEn != nil {
                EntregaConfirmadaBanner(estado: pedido.estado, confirmadoEn: pedido.confirmadoEn)
            }

            if pedido.esDelivery && pedido.estado == "EN_CAMINO" {
                MapaEntregaView(etaMinutos: etaMinutos)
            }

            DetallePedidoView(pedido: pedido)

            if let onVerDetalles {
                Button(action: onVerDetalles) { Text("Ver detalles") }
                    .buttonStyle(.secundario)
            }
        }
    }

    private var cabecera: some View {
        HStack(spacing: 14) {
            Image(systemName: EstadoPedidoUI.icono(pedido.estado))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(colorEstado.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .symbolEffect(.pulse, isActive: pedido.activo)
            VStack(alignment: .leading, spacing: 2) {
                Text(EstadoPedidoUI.titulo(pedido.estado))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.texto)
                Text(EstadoPedidoUI.subtitulo(pedido.estado))
                    .font(.subheadline)
                    .foregroundStyle(AppColors.gris)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pasos

private struct PasosPedidoView: View {
    let pasos: [String]
    let indice: Int
    let creado: Date

    private let nombres = ["CONFIRMADO": "Confirmado", "EN_PREPARACION": "Preparando",
                           "EN_CAMINO": "En camino", "ENTREGADO": "Entregado"]
    private let iconos = ["CONFIRMADO": "receipt", "EN_PREPARACION": "flame.fill",
                          "EN_CAMINO": "scooter", "ENTREGADO": "checkmark"]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(pasos.enumerated()), id: \.offset) { i, paso in
                let hecho = i <= indice
                VStack(spacing: 8) {
                    ZStack {
                        // Línea: mitad izquierda y derecha del círculo
                        HStack(spacing: 0) {
                            Rectangle().fill(i == 0 ? .clear : (i <= indice ? AppColors.primary : AppColors.hairline))
                            Rectangle().fill(i == pasos.count - 1 ? .clear : (i < indice ? AppColors.primary : AppColors.hairline))
                        }
                        .frame(height: 3)

                        Image(systemName: iconos[paso] ?? "circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(hecho ? .white : AppColors.grisClaro)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(hecho ? AppColors.primary : AppColors.surface))
                            .overlay(Circle().stroke(hecho ? AppColors.primary : AppColors.hairline, lineWidth: 2))
                            .shadow(color: i == indice ? AppColors.primary.opacity(0.35) : .clear, radius: 6)
                    }
                    Text(nombres[paso] ?? paso)
                        .font(.caption.weight(hecho ? .bold : .medium))
                        .foregroundStyle(hecho ? AppColors.texto : AppColors.gris)
                        .multilineTextAlignment(.center)
                    if i == 0 {
                        Text(creado.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(AppColors.gris)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Paso \(i + 1) de \(pasos.count): \(nombres[paso] ?? paso), \(hecho ? "completado" : "pendiente")")
                .accessibilityAddTraits(i == indice ? .isSelected : [])
            }
        }
        .animation(.snappy, value: indice)
    }
}

// MARK: - Mapa ilustrativo

private struct MapaEntregaView: View {
    let etaMinutos: Int?

    private func burbuja(_ simbolo: String) -> some View {
        Image(systemName: simbolo)
            .foregroundStyle(AppColors.primary)
            .frame(width: 42, height: 42)
            .background(AppColors.surface, in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Canvas { ctx, s in
                    let calle = AppColors.surface.opacity(0.75)
                    var x = s.width * 0.1
                    while x < s.width {
                        var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: s.height))
                        ctx.stroke(p, with: .color(calle), lineWidth: 9)
                        x += s.width * 0.21
                    }
                    var y = s.height * 0.12
                    while y < s.height {
                        var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: s.width, y: y))
                        ctx.stroke(p, with: .color(calle), lineWidth: 9)
                        y += s.height * 0.28
                    }
                    var ruta = Path()
                    ruta.move(to: CGPoint(x: s.width * 0.2, y: s.height * 0.28))
                    ruta.addLine(to: CGPoint(x: s.width * 0.2, y: s.height * 0.55))
                    ruta.addLine(to: CGPoint(x: s.width * 0.82, y: s.height * 0.55))
                    ruta.addLine(to: CGPoint(x: s.width * 0.82, y: s.height * 0.3))
                    ctx.stroke(ruta, with: .color(AppColors.primary),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 5]))
                }
                burbuja("scooter").position(x: w * 0.2, y: h * 0.28)
                burbuja("house.fill").position(x: w * 0.82, y: h * 0.3)
            }
        }
        .frame(height: 200)
        .background(Color.adaptable(light: 0xEFE7DB, dark: 0x2E2620))
        .overlay(alignment: .bottomLeading) {
            if let etaMinutos {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tiempo estimado").font(.caption2).foregroundStyle(AppColors.gris)
                    Label("\(etaMinutos) min", systemImage: "clock")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(AppColors.texto)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppColors.hairline))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etaMinutos.map { "Tu pedido está en camino. Tiempo estimado \($0) minutos" }
                            ?? "Tu pedido está en camino")
    }
}

// MARK: - Detalle

private struct DetallePedidoView: View {
    let pedido: Pedido

    private var esYape: Bool { pedido.metodoPago == "YAPE" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalle del pedido").font(.headline)

            ForEach(pedido.items) { it in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(it.cantidad)×")
                        .font(.footnote.weight(.bold)).foregroundStyle(AppColors.primary)
                    Text(it.nombre).font(.subheadline).foregroundStyle(AppColors.texto).lineLimit(2)
                    Spacer(minLength: 8)
                    Text(it.subtotal.soles).font(.subheadline).foregroundStyle(AppColors.gris)
                }
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text("Total").font(.headline)
                Spacer()
                Text(pedido.total.soles).font(.precio(.title3)).foregroundStyle(AppColors.primary)
            }

            Label(esYape ? "Pago con Yape" : "Pago en efectivo",
                  systemImage: esYape ? "qrcode" : "banknote")
                .font(.footnote).foregroundStyle(AppColors.gris)

            if let vuelto = pedido.vuelto, vuelto > 0 {
                Text("Vuelto a recibir: \(vuelto.soles)")
                    .font(.footnote.weight(.semibold)).foregroundStyle(AppColors.texto)
            }
        }
        .tarjeta()
    }
}
