import SwiftUI

/// Stepper en cápsula. Botones de 44 pt (mínimo HIG).
/// `minimoEliminar`: en 1 el "−" pasa a papelera (carrito). Si es false, el "−" se deshabilita en 1.
struct SelectorCantidad: View {
    let cantidad: Int
    let maximo: Int
    var minimoEliminar = false
    let onMenos: () -> Void
    let onMas: () -> Void

    private var esEliminar: Bool { minimoEliminar && cantidad <= 1 }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onMenos) {
                Image(systemName: esEliminar ? "trash" : "minus")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(esEliminar ? AppColors.danger : AppColors.cacaoTexto)
                    .frame(width: 44, height: 44)
            }
            .disabled(!minimoEliminar && cantidad <= 1)
            .accessibilityLabel(esEliminar ? "Quitar producto" : "Disminuir cantidad")

            Text("\(cantidad)")
                .font(.body.weight(.bold).monospacedDigit())
                .foregroundStyle(AppColors.texto)
                .frame(minWidth: 24)
                .contentTransition(.numericText(value: Double(cantidad)))

            Button(action: onMas) {
                Image(systemName: "plus")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(cantidad >= maximo)
            .accessibilityLabel("Aumentar cantidad")
        }
        .buttonStyle(.borderless)
        .background(AppColors.kraftClaro, in: Capsule())
        .animation(.snappy, value: cantidad)
        .sensoryFeedback(.selection, trigger: cantidad)
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(cantidad)")
    }
}
