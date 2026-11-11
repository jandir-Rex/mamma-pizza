import SwiftUI

struct PedidoExitoView: View {
    let codigo: String
    var onVerSeguimiento: () -> Void
    var onVolver: () -> Void
    @State private var aparecio = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().fill(AppColors.success.opacity(0.10))
                    .frame(width: 200, height: 200)
                    .scaleEffect(aparecio ? 1 : 0.4)
                Circle().fill(AppColors.success.opacity(0.16))
                    .frame(width: 150, height: 150)
                    .scaleEffect(aparecio ? 1 : 0.4)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(AppColors.success)
                    .symbolEffect(.bounce, value: aparecio)
                    .scaleEffect(aparecio ? 1 : 0.3)
            }
            .animation(.spring(duration: 0.7, bounce: 0.35), value: aparecio)

            VStack(spacing: 6) {
                Text("¡Pedido recibido!").font(.marca(.largeTitle))
                Text("Te avisaremos apenas confirmemos tu pago")
                    .font(.subheadline).foregroundStyle(AppColors.gris)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text("CÓDIGO DE PEDIDO")
                    .font(.caption.weight(.semibold)).tracking(1.2)
                    .foregroundStyle(AppColors.gris)
                Text(codigo)
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(AppColors.cacaoTexto)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.kraftClaro, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColors.kraft, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
            .padding(.top, 28)
            .accessibilityElement(children: .combine)

            Spacer()

            VStack(spacing: 4) {
                Button(action: onVerSeguimiento) {
                    Label("Ver seguimiento", systemImage: "scooter")
                }
                .buttonStyle(.primario)

                Button("Volver al menú", action: onVolver)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.gris)
                    .frame(minHeight: 44)
            }
        }
        .padding(24)
        .fondoApp()
        .sensoryFeedback(.success, trigger: aparecio)
        .onAppear { aparecio = true }
    }
}
