import SwiftUI
import AVKit

struct AdCarouselItem: Identifiable {
    enum Kind { case image, video }
    let id = UUID()
    let name: String
    let kind: Kind
    let duration: Double
}

struct AdCarousel: View {
    var onVerMenu: () -> Void = {}

    let items: [AdCarouselItem] = [
        .init(name: "ad1", kind: .image, duration: 3),
        .init(name: "ad2", kind: .image, duration: 3),
        .init(name: "ad3", kind: .image, duration: 3),
        .init(name: "ad4", kind: .image, duration: 3),
        .init(name: "ad5", kind: .video, duration: 8),
        .init(name: "ad6", kind: .video, duration: 8)
    ]

    // Ajuste profesional: 200 es el punto dulce entre impacto y espacio.
    private let height: CGFloat = 200
    @State private var index = 0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black

            content(items[index])
                .id(index)
                .transition(.opacity)

            // Oscurecido superior para legibilidad de indicadores si los hay
            LinearGradient(
                colors: [.black.opacity(0.3), .clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("HECHA AL MOMENTO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5), in: Capsule())

                Text("La verdadera pizza\nes una buena idea")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button { onVerMenu() } label: {
                    Label("Ver menú", systemImage: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.cacao)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(AppColors.kraft, in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(20)

            // Indicadores más finos y discretos
            HStack(spacing: 6) {
                ForEach(items.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Color.white : Color.white.opacity(0.35))
                        .frame(width: i == index ? 16 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: index)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(items[index].duration))
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: 0.5)) {
                    index = (index + 1) % items.count
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ item: AdCarouselItem) -> some View {
        switch item.kind {
        case .image:
            if let path = Bundle.main.path(forResource: item.name, ofType: "jpeg"),
               let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .clipped()
            } else {
                Color.gray
            }
        case .video:
            if let url = Bundle.main.url(forResource: item.name, withExtension: "mp4") {
                AdVideoView(url: url)
            } else {
                Color.gray
            }
        }
    }
}

struct AdVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> AdPlayerUIView {
        let view = AdPlayerUIView()
        let player = AVPlayer(url: url)
        player.isMuted = true
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        player.play()
        return view
    }

    func updateUIView(_ uiView: AdPlayerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: AdPlayerUIView, coordinator: ()) {
        uiView.playerLayer.player?.pause()
    }
}

final class AdPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}