import SwiftUI
import AVKit

struct LoopingVideoBackground: UIViewRepresentable {
    let name: String

    @Environment(\.scenePhase) private var scenePhase

    final class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AdPlayerUIView {
        let view = AdPlayerUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return view }
        let player = AVQueuePlayer()
        player.isMuted = true
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        context.coordinator.player = player
        view.playerLayer.player = player
        player.play()
        return view
    }

    func updateUIView(_ uiView: AdPlayerUIView, context: Context) {
        // Pausar en background, reanudar en foreground.
        guard let player = context.coordinator.player else { return }
        if scenePhase == .active {
            if player.timeControlStatus != .playing { player.play() }
        } else {
            if player.timeControlStatus == .playing { player.pause() }
        }
    }

    static func dismantleUIView(_ uiView: AdPlayerUIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        coordinator.looper = nil
        uiView.playerLayer.player = nil
    }
}