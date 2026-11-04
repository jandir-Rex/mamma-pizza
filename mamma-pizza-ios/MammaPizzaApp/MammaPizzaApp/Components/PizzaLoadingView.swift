import SwiftUI

struct PizzaLoadingView: View {
    var size: CGFloat = 120
    var mensaje: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    var body: some View {
        VStack(spacing: 14) {
            if reducirMovimiento {
                ProgressView().controlSize(.large)
            } else {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.6) / 3.6
                    Canvas { ctx, sz in Self.dibujar(&ctx, sz, t) }
                        .frame(width: size, height: size)
                }
            }
            if let mensaje {
                Text(mensaje).font(.footnote).foregroundStyle(AppColors.gris)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mensaje ?? "Cargando")
    }

    private static let crust = Color(hex: 0xE0A55C)
    private static let crustDark = Color(hex: 0xC17D3A)
    private static let cheese = Color(hex: 0xF6C24C)
    private static let sauce = Color(hex: 0xB8432E)
    private static let pepperoni = Color(hex: 0xA6321F)
    private static let slices = 8

    private static func dibujar(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = size.width / 2 - 6
        let sliceAngle = 2 * Double.pi / Double(slices)

        // Leve "respiración" de escala
        let escala = 0.97 + 0.03 * sin(t * 2 * .pi)
        ctx.translateBy(x: center.x, y: center.y)
        ctx.scaleBy(x: escala, y: escala)
        ctx.translateBy(x: -center.x, y: -center.y)

        func circulo(_ r: Double) -> Path {
            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        }
        func punto(_ ang: Double, _ r: Double) -> CGPoint {
            CGPoint(x: center.x + cos(ang) * r, y: center.y + sin(ang) * r)
        }

        ctx.fill(circulo(radius), with: .color(crust))
        ctx.stroke(circulo(radius), with: .color(crustDark), lineWidth: 3)
        ctx.fill(circulo(radius * 0.88), with: .color(sauce.opacity(0.18)))

        for i in 0..<slices {
            var local = t - Double(i) / Double(slices)
            local -= floor(local)
            let opacity: Double = local < 0.45
                ? 1 - pow(1 - local / 0.45, 3)               // easeOut
                : local < 0.7 ? 1.0
                : pow(1 - (local - 0.7) / 0.3, 2)            // easeIn
            let start = -Double.pi / 2 + Double(i) * sliceAngle

            // Tajada (polígono que aproxima el arco)
            var tajada = Path()
            tajada.move(to: center)
            for k in 0...10 { tajada.addLine(to: punto(start + sliceAngle * Double(k) / 10, radius * 0.88)) }
            tajada.closeSubpath()
            ctx.fill(tajada, with: .color(cheese.opacity(min(1, 0.25 + 0.75 * opacity))))

            var linea = Path()
            linea.move(to: center)
            linea.addLine(to: punto(start, radius * 0.88))
            ctx.stroke(linea, with: .color(crustDark.opacity(0.25)), lineWidth: 1.4)

            // Pepperoni (2 por tajada)
            let mid = start + sliceAngle / 2
            for f in [0.38, 0.68] {
                let ang = mid + (f == 0.38 ? -0.09 : 0.11)
                let c = punto(ang, radius * f)
                let r = radius * 0.085
                let dot = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                ctx.fill(dot, with: .color(pepperoni.opacity(min(0.95, opacity * 0.95))))
                ctx.stroke(dot, with: .color(.black.opacity(opacity * 0.15)), lineWidth: 1)
            }
        }
        ctx.fill(circulo(radius * 0.05), with: .color(crustDark))
    }
}
