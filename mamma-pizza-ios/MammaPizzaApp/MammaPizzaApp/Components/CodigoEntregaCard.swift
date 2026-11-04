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
    @ScaledMetric(relativeTo: .largeTitle) private var ancho: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var alto: CGFloat = 64

    private var visible: Bool {
        canal == "DELIVERY" && estado == "EN_CAMINO" && (codigo?.count == 4)
    }
    private var bloqueado: Bool { intentosFallidos >= maxIntentos }

    var body: some View {
        if visible, let codigo {
            let digitos = Array(codigo).map(String.init)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Tu código de entrega", systemImage: "checkmark.shield")
                        .font(.headline)
                        .foregroundStyle(AppColors.texto)
                    Spacer()
                    Button {
                        oculto.toggle()
                    } label: {
                        Image(systemName: oculto ? "eye" : "eye.slash")
                            .frame(width: 44, height: 44)
                    }
                    .foregroundStyle(AppColors.gris)
                    .accessibilityLabel(oculto ? "Mostrar código" : "Ocultar código")
                }

                Text("Díctaselo al repartidor cuando llegue con tu pedido. No lo compartas antes: así confirmamos que la entrega es tuya.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.gris)

                HStack(spacing: 10) {
                    ForEach(Array(digitos.enumerated()), id: \.offset) { _, d in
                        Text(oculto ? "•" : d)
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: ancho, height: alto)
                            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.primary.opacity(0.5), lineWidth: 1.5))
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
                    Label(copiado ? "Copiado" : "Copiar", systemImage: copiado ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .tint(AppColors.primary)
                .disabled(oculto)
                .frame(maxWidth: .infinity)
                .sensoryFeedback(.success, trigger: copiado) { _, nuevo in nuevo }

                if bloqueado {
                    Text("El repartidor agotó los intentos. Comunícate con el local para que reinicien tu código.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.danger)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(16)
            .background(AppColors.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.primary.opacity(0.35), lineWidth: 1.5))
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
            .background(AppColors.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
