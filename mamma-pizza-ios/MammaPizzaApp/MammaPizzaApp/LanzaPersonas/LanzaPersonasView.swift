import SwiftUI
import UIKit

struct LanzaPersonasView: UIViewControllerRepresentable {
    var onClose: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = ViewController()
        // El cierre se maneja DENTRO del ViewController (botón X nativo)
        // y solo notifica a SwiftUI para cerrar el fullScreenCover.
        vc.onClose = {
            onClose()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct LanzaPersonasContainer: View {
    var onClose: () -> Void
    @State private var didLock = false

    var body: some View {
        LanzaPersonasView(onClose: {
            // Restaurar orientación vertical antes de cerrar
            AppDelegate.orientationLock = .portrait
            forceOrientation(.portrait)
            // Cerrar el fullScreenCover
            onClose()
        })
        .ignoresSafeArea()
        .onAppear {
            guard !didLock else { return }
            didLock = true
            AppDelegate.orientationLock = .landscape
            forceOrientation(.landscapeRight)
        }
    }
}

@MainActor
func forceOrientation(_ mask: UIInterfaceOrientationMask) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
}
