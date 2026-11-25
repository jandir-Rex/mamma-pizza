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
            // 1) Permitir portrait en la app.
            AppDelegate.orientationLock = .portrait
            // 2) Forzar la geometría DESPUÉS de que el cover se cierre,
            //    con reintento corto por si el scene aún está en transición.
            forceOrientation(.portrait)
            onClose()
            DispatchQueue.main.async { forceOrientation(.portrait) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { forceOrientation(.portrait) }
        })
        .ignoresSafeArea()
        .onAppear {
            guard !didLock else { return }
            didLock = true
            AppDelegate.orientationLock = .landscape
            DispatchQueue.main.async { forceOrientation(.landscapeRight) }
        }
    }
}

@MainActor
func forceOrientation(_ mask: UIInterfaceOrientationMask) {
    // Preferir el scene activo (foregroundActive) para evitar scenes huérfanos.
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    guard let s = scene else { return }
    s.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
    s.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    // Recorrer la jerarquía presentada para refrescar soporte en iPad.
    var vc: UIViewController? = s.keyWindow?.rootViewController
    while let presented = vc?.presentedViewController { vc = presented }
    vc?.setNeedsUpdateOfSupportedInterfaceOrientations()
}
