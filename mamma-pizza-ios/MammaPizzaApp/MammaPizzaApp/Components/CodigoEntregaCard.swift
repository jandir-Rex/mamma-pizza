import SwiftUI

/// Muestra al CLIENTE el código de 4 dígitos que debe dictarle al repartidor.
/// Solo visible con canal DELIVERY + estado EN_CAMINO + código generado.
struct CodigoEntregaCard: View {
    let codigo: String?
    let estado: String
    let canal: String
    var intentosFallidos: Int = 0
    var maxIntentos: Int = 3

    @State private var oculto = false
    @State private var copiado = false
    @ScaledMetric(relativeTo: .largeTitle) private var ancho: CGFloat = 54
    @ScaledMetric(relativeTo: .largeTitle) private var alto: CGFloat = 66

    private var visible: Bool {
        canal == "DELIVERY" && estado == "EN_CAMINO" && (codigo?.count == 4)
    }
    private var bloqueado: Bool { intentosFallidos >= maxIntentos }

    var body: some View {
        if visible, let codigo {
            let digitos = Array(codigo).map(String.init)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Tu código de entrega", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { oculto.toggle() } label: {
                        Image(systemName: oculto ? "eye" : "eye.slash")
                            .frame(width: 44, height: 44)
                    }
                    .foregroundStyle(AppColors.kraft)
                    .accessibilityLabel(oculto ? "Mostrar código" : "Ocultar código")
                }

                Text("Díctaselo al repartidor cuando llegue con tu pedido. No lo compartas antes: así confirmamos que la entrega es tuya.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 10) {
                    ForEach(Array(digitos.enumerated()), id: \.offset) { _, d in
                        Text(oculto ? "•" : d)
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(AppColors.cacao)
                            .frame(width: ancho, height: alto)
                            .background(Color(hex: 0xF3E3C8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(oculto ? "Código de entrega oculto"
                                           : "Código de entrega \(digitos.joined(separator: " "))")

                Button {
                    UIPasteboard.general.string = codigo
                    copiado = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copiado = false
                    }
                } label: {
                    Label(copiado ? "Copiado" : "Copiar código",
                          systemImage: copiado ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.cacao)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(AppColors.kraft, in: Capsule())
                }
                .buttonStyle(.presion)
                .disabled(oculto)
                .opacity(oculto ? 0.5 : 1)
                .sensoryFeedback(.success, trigger: copiado) { _, nuevo in nuevo }

                if bloqueado {
                    Text("El repartidor agotó los intentos. Comunícate con el local para que reinicien tu código.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.tomate.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(18)
            .background(AppColors.marcaDegradado, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

/// Banner cuando el pedido se entregó validando el código.
struct EntregaConfirmadaBanner: View {
    let estado: String
    let confirmadoEn: Date?

    var body: some View {
        if estado == "ENTREGADO", let confirmadoEn {
            Label {
                Text("Entrega confirmada con tu código a las \(confirmadoEn.formatted(date: .omitted, time: .shortened)). ¡Buen provecho!")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .foregroundStyle(AppColors.success)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
