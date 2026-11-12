import SwiftUI

/// Pantalla de carga: aro circular animado con el texto "Cargando".
struct PizzaLoadingView: View {
    var size: CGFloat = 48
    var mensaje: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    private let grosor: CGFloat = 4

    var body: some View {
        VStack(spacing: 16) {
            if reducirMovimiento {
                ProgressView().controlSize(.large)
            } else {
                aro
            }

            Text(mensaje ?? "Cargando")
                .font(.footnote.weight(.medium))
                .tracking(0.6)
                .foregroundStyle(AppColors.gris)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mensaje ?? "Cargando")
    }

    private var aro: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let giro = (t.truncatingRemainder(dividingBy: 1.2) / 1.2) * 360
            let largo = 0.18 + 0.42 * (0.5 + 0.5 * sin(t * 2 * .pi / 1.6))

            ZStack {
                Circle()
                    .stroke(AppColors.primary.opacity(0.12), lineWidth: grosor)

                Circle()
                    .trim(from: 0, to: largo)
                    .stroke(AppColors.primary,
                            style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                    .rotationEffect(.degrees(giro - 90))

                Circle()
                    .trim(from: 0, to: 0.08)
                    .stroke(AppColors.mostaza,
                            style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                    .rotationEffect(.degrees(-giro * 0.6 + 90))
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}
