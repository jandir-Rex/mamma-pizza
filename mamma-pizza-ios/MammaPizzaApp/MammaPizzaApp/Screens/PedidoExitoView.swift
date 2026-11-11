import SwiftUI

struct PedidoExitoView: View {
    let codigo: String
    var onVerSeguimiento: () -> Void
    var onVolver: () -> Void
    @State private var aparecio = false

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(AppColors.success)
                .symbolEffect(.bounce, value: aparecio)
                .padding(.bottom, 16)
            Text("¡Pedido recibido!").font(.title.weight(.heavy))
            Text("Código: \(codigo)").foregroundStyle(AppColors.gris)
            Text("Te avisaremos apenas confirmemos tu pago")
                .font(.footnote).foregroundStyle(AppColors.gris).multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: 8) {
                Button(action: onVerSeguimiento) {
                    Text("Ver seguimiento").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                Button("Volver al menú", action: onVolver).foregroundStyle(AppColors.gris)
            }
        }
        .padding(28)
        .background(AppColors.bg)
        .sensoryFeedback(.success, trigger: aparecio)
        .onAppear { aparecio = true }
        .accessibilityElement(children: .contain)
    }
}
