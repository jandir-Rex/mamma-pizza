import SwiftUI

/// Pantalla de entrada: degradado cacao, brasas flotantes, logo que entra con un anillo
/// que se "dibuja" y el nombre apareciendo letra por letra. Llama a `onTerminar` al acabar.
struct SplashView: View {
    var onTerminar: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reducir
    @State private var anillo: CGFloat = 0
    @State private var emblema = false
    @State private var letras = false
    @State private var detalle = false
    @State private var brillo = false

    private let nombre = Array("MammaPizza")

    var body: some View {
        ZStack {
            AppColors.marcaDegradado.ignoresSafeArea()

            // Círculos de marca (mismo lenguaje que el banner del Home)
            Circle().fill(AppColors.kraft.opacity(0.08)).frame(width: 380).offset(x: 140, y: -300)
            Circle().fill(AppColors.tomate.opacity(0.16)).frame(width: 240).offset(x: -150, y: 320)

            if !reducir { Brasas().ignoresSafeArea() }

            VStack(spacing: 34) {
                emblemaView
                VStack(spacing: 14) {
                    titulo
                    divisor
                    Text("PIZZA HOUSE")
                        .font(.footnote.weight(.bold))
                        .tracking(detalle ? 6 : 2)
                        .foregroundStyle(AppColors.kraft)
                        .opacity(detalle ? 1 : 0)
                    Text("Hecha al horno, hecha con cariño")
                        .font(.system(.footnote, design: .serif).italic())
                        .foregroundStyle(AppColors.kraft.opacity(0.7))
                        .opacity(detalle ? 1 : 0)
                        .offset(y: detalle ? 0 : 8)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mamma Pizza")
        .task { await animar() }
    }

    private var emblemaView: some View {
        ZStack {
            // Resplandor de horno
            Circle()
                .fill(AppColors.mostaza.opacity(0.35))
                .frame(width: 120, height: 120)
                .blur(radius: 36)
                .scaleEffect(brillo ? 1.25 : 0.85)
                .opacity(emblema ? 1 : 0)

            // Anillo que se dibuja
            Circle()
                .trim(from: 0, to: anillo)
                .stroke(AppColors.kraft, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            // Tu logo
            Image("MammaPizzaLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 122, height: 122)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColors.kraft.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
                .scaleEffect(emblema ? 1 : 0.5)
                .opacity(emblema ? 1 : 0)
        }
    }

    private var titulo: some View {
        HStack(spacing: 0) {
            ForEach(Array(nombre.enumerated()), id: \.offset) { i, letra in
                Text(String(letra))
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(letras ? 1 : 0)
                    .offset(y: letras ? 0 : 14)
                    .animation(.spring(duration: 0.5, bounce: 0.25).delay(Double(i) * 0.05), value: letras)
            }
        }
    }

    private var divisor: some View {
        HStack(spacing: 10) {
            Rectangle().fill(AppColors.kraft.opacity(0.5)).frame(width: detalle ? 36 : 0, height: 1)
            Image(systemName: "diamond.fill").font(.system(size: 6)).foregroundStyle(AppColors.mostaza)
            Rectangle().fill(AppColors.kraft.opacity(0.5)).frame(width: detalle ? 36 : 0, height: 1)
        }
        .opacity(detalle ? 1 : 0)
    }

    private func animar() async {
        if reducir {
            anillo = 1; emblema = true; letras = true; detalle = true
            try? await Task.sleep(for: .seconds(1.2))
            onTerminar()
            return
        }
        withAnimation(.easeInOut(duration: 1.0)) { anillo = 1 }
        withAnimation(.spring(duration: 0.7, bounce: 0.35).delay(0.25)) { emblema = true }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { brillo = true }
        try? await Task.sleep(for: .seconds(0.7))
        letras = true
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation(.easeOut(duration: 0.7)) { detalle = true }
        try? await Task.sleep(for: .seconds(1.3))
        onTerminar()
    }
}

/// Brasas que suben despacio y se desvanecen.
private struct Brasas: View {
    private let cantidad = 18

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                for i in 0..<cantidad {
                    let semilla = Double(i) * 12.9898
                    let velocidad = 0.05 + 0.04 * (sin(semilla) * 0.5 + 0.5)
                    let fase = (t * velocidad + Double(i) / Double(cantidad)).truncatingRemainder(dividingBy: 1)
                    let base = size.width * (0.5 + 0.5 * sin(semilla * 3.1))
                    let x = base + 14 * sin(t + semilla)
                    let y = size.height * (1.05 - 1.1 * fase)
                    let r = 1.5 + 2.0 * (cos(semilla) * 0.5 + 0.5)
                    let opacidad = sin(fase * .pi) * 0.7
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(AppColors.mostaza.opacity(opacidad)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
