import SwiftUI

struct MammaPizzaLogo: View {
    var body: some View {
        VStack(spacing: 12) {
            // Reemplaza por tu logo real: Image("LogoMamma") en Assets.xcassets
            Image(systemName: "flame.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.kraft)
                .frame(width: 76, height: 76)
                .background(AppColors.marcaDegradado, in: Circle())
                .shadow(color: AppColors.cacao.opacity(0.3), radius: 12, y: 6)

            VStack(spacing: 2) {
                Text("MammaPizza")
                    .font(.system(.largeTitle, design: .serif, weight: .heavy))
                    .foregroundStyle(AppColors.cacaoTexto)
                Text("PIZZA HOUSE")
                    .font(.caption2.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mamma Pizza")
    }
}
