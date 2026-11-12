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

    private let height: CGFloat = 200
    @State private var index = 0
    @State private var enPantalla = true
    @State private var playerActual: AVPlayer?
    @Environment(\.scenePhase) private var scenePhase

    private var debeReproducir: Bool {
        enPantalla && scenePhase == .active && items[index].kind == .video
    }

    var body: some View {
        GeometryReader { geo in
            let visible = geo.frame(in: .global).maxY > 0 && geo.frame(in: .global).minY < UIScreen.main.bounds.height
            ZStack(alignment: .bottomLeading) {
                Color.black

                content(items[index])
                    .id(index)
                    .transition(.opacity)

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
            .onChange(of: visible) { _, nuevaVisibilidad in
                enPantalla = nuevaVisibilidad
                actualizarReproduccion()
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        .onChange(of: scenePhase) { _, _ in actualizarReproduccion() }
        .onChange(of: index) { _, _ in actualizarReproduccion() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(items[index].duration))
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: 0.5)) {
                    index = (index + 1) % items.count
                }
            }
        }
        .onDisappear {
            playerActual?.pause()
            playerActual = nil
        }
    }

    private func actualizarReproduccion() {
        guard let player = playerActual else { return }
        if debeReproducir {
            player.play()
        } else {
            player.pause()
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
                AdVideoView(
                    url: url,
                    debeReproducir: debeReproducir,
                    onPlayerCreado: { player in
                        playerActual = player
                    }
                )
            } else {
                Color.gray
            }
        }
    }
}

struct AdVideoView: UIViewRepresentable {
    let url: URL
    let debeReproducir: Bool
    let onPlayerCreado: (AVPlayer) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AdPlayerUIView {
        let view = AdPlayerUIView()
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill

        context.coordinator.observadorLoop = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            if debeReproducir { player.play() }
        }

        onPlayerCreado(player)
        if debeReproducir { player.play() }
        return view
    }

    func updateUIView(_ uiView: AdPlayerUIView, context: Context) {
        guard let player = uiView.playerLayer.player else { return }
        if debeReproducir {
            if player.timeControlStatus != .playing { player.play() }
        } else {
            if player.timeControlStatus == .playing { player.pause() }
        }
    }

    static func dismantleUIView(_ uiView: AdPlayerUIView, coordinator: Coordinator) {
        if let obs = coordinator.observadorLoop {
            NotificationCenter.default.removeObserver(obs)
            coordinator.observadorLoop = nil
        }
        uiView.playerLayer.player?.pause()
        uiView.playerLayer.player = nil
    }

    final class Coordinator {
        var observadorLoop: NSObjectProtocol?
    }
}

final class AdPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}