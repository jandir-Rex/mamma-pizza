import SwiftUI

struct MammaPizzaLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            // Reemplaza por tu logo: Image("LogoMamma") en Assets.xcassets
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(AppColors.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("MammaPizza")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppColors.texto)
                Text("PIZZA HOUSE")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mamma Pizza")
    }
}
