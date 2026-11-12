import SwiftUI
import AVKit

struct LoopingVideoBackground: UIViewRepresentable {
    let name: String

    final class Coordinator {
        var looper: AVPlayerLooper?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AdPlayerUIView {
        let view = AdPlayerUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return view }
        let player = AVQueuePlayer()
        player.isMuted = true
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        view.playerLayer.player = player
        player.play()
        return view
    }

    func updateUIView(_ uiView: AdPlayerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: AdPlayerUIView, coordinator: Coordinator) {
        uiView.playerLayer.player?.pause()
    }
}
