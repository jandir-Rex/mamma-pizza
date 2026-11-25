import UIKit
import AVFoundation

// =====================================================================
//  LANZA PERSONAS · tirachinas con UIKit Dynamics
//  Rúbrica del lab:
//   - Animaciones UIView spring y keyframes ........ showOverlay, floatingText, shakeWorld, loadNextProjectile
//   - UIDynamicAnimator + límites + física ......... setupPhysics, addBody (density/elasticity/friction)
//   - UICollisionBehaviorDelegate + gravedad + push  collisionBehavior(...), gravity, impulse(...)
// =====================================================================

// MARK: - Tipos de proyectil
enum Kind {
    case normal, heavy, split, dash

    var density: CGFloat { self == .heavy ? 3 : 1 }
    var size: CGFloat {
        switch self {
        case .heavy: return 54
        case .split: return 40
        default: return 44
        }
    }
    var damage: CGFloat { self == .heavy ? 1.8 : 1 }
    var color: UIColor {
        switch self {
        case .normal: return .white
        case .heavy: return .systemRed
        case .split: return .systemOrange
        case .dash: return .systemCyan
        }
    }
    var hint: String {
        switch self {
        case .normal: return "Arrastra hacia atrás, apunta y suelta"
        case .heavy: return "PESADO: toca en el aire para caer en picada"
        case .split: return "DIVISIBLE: toca en el aire para dividirse en 3"
        case .dash: return "VELOZ: toca en el aire para acelerar"
        }
    }
}

// MARK: - Materiales de los bloques
enum Mat {
    case wood, stone, glass

    var color: UIColor {
        switch self {
        case .wood: return UIColor(red: 0.72, green: 0.50, blue: 0.28, alpha: 1)
        case .stone: return UIColor(white: 0.55, alpha: 1)
        case .glass: return UIColor(red: 0.60, green: 0.85, blue: 0.95, alpha: 0.85)
        }
    }
    var hp: CGFloat {
        switch self {
        case .wood: return 3
        case .stone: return 7
        case .glass: return 1.2
        }
    }
    var density: CGFloat {
        switch self {
        case .wood: return 1
        case .stone: return 2.5
        case .glass: return 0.6
        }
    }
    var points: Int {
        switch self {
        case .wood: return 50
        case .stone: return 100
        case .glass: return 30
        }
    }
}

// MARK: - Vistas físicas
class DamageView: UIView {
    var isDead = false          // se contabiliza una sola vez
    var hp: CGFloat = 1
    var points = 0
    var isRival = false
}

final class BlockView: DamageView {
    var material: Mat = .wood
}

final class RivalView: DamageView {
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { return .ellipse }
}

final class ProjectileView: UIImageView {
    var personName = ""         // persona_N (imagen y sonido)
    var launched = false        // un proyectil solo se lanza una vez
    var kind: Kind = .normal
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { return .ellipse }
}

// =====================================================================
final class ViewController: UIViewController, UICollisionBehaviorDelegate {

    // Callback para cerrar el minijuego desde SwiftUI
    var onClose: (() -> Void)?

    private enum State { case menu, ready, flying, resolving, ended }

    // MARK: Configuración
    private let maxStretch: CGFloat = 110
    private let speedFactor: CGFloat = 9.5
    private let rivalSize: CGFloat = 34

    // MARK: Vistas
    private let sky = UIView()
    private let gradient = CAGradientLayer()
    private let world = UIView()
    private let bandLayer = CAShapeLayer()
    private let leftPost = UIView()
    private let rightPost = UIView()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let hintLabel = UILabel()
    private let restartButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)
    private var overlay: UIView?
    private var queueViews: [UIImageView] = []
    private var dotViews: [UIView] = []

    // MARK: Física
    private var animator: UIDynamicAnimator!
    private var collision: UICollisionBehavior!
    private var gravity: UIGravityBehavior!
    private var debrisBehavior: UIDynamicItemBehavior!
    private var bodies: [UIView: UIDynamicItemBehavior] = [:]
    private var lastSpeed: [UIView: CGFloat] = [:]

    // MARK: Estado del juego
    private var state: State = .menu
    private var level = 1
    private var score = 0
    private var armed = false
    private var worldActive = false
    private var abilityUsed = false
    private var dragging = false
    private var finishScheduled = false
    private var queue: [Kind] = []
    private var current: ProjectileView?
    private var flying: [ProjectileView] = []
    private var blocks: [BlockView] = []
    private var rivals: [RivalView] = []
    private var personImages: [UIImage] = []
    private var personIndex = 0
    private var personNames: [String] = []
    private var watchdog: Timer?
    private var sceneToken = 0
    private var audioPlayer: AVAudioPlayer?
    private var launchTime = Date()
    private var restSince: Date?
    private var anchor = CGPoint.zero
    private var groundY: CGFloat = 0

    override var prefersStatusBarHidden: Bool { return true }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    // MARK: Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        sky.frame = view.bounds
        sky.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradient.colors = [UIColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 1).cgColor,
                           UIColor(red: 0.88, green: 0.96, blue: 1.00, alpha: 1).cgColor]
        sky.layer.addSublayer(gradient)
        view.addSubview(sky)

        world.frame = view.bounds
        world.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        world.backgroundColor = .clear
        view.addSubview(world)

        bandLayer.strokeColor = UIColor(red: 0.25, green: 0.14, blue: 0.08, alpha: 1).cgColor
        bandLayer.lineWidth = 6
        bandLayer.lineCap = .round
        bandLayer.fillColor = nil
        world.layer.addSublayer(bandLayer)

        setupHUD()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = sky.bounds
        
        // Ajuste de rotación: reiniciar el nivel actual con las nuevas dimensiones
        if sky.frame.size != view.bounds.size {
            sky.frame = view.bounds
            world.frame = view.bounds
            gradient.frame = sky.bounds
            
            // Reconstruir la escena completa con el nuevo tamaño
            if animator != nil && !personImages.isEmpty {
                let currentLevel = level
                let currentScore = score
                let currentState = state
                
                layoutScene()
                setupPhysics()
                
                if currentState != .menu {
                    loadScene(currentLevel)
                    score = currentScore
                    updateHUD()
                } else {
                    showMenu()
                }
            }
        }
    }
    
    /// Reposiciona los elementos existentes al nuevo tamaño de pantalla
    /// SIN recrear, SIN tocar rivals/blocks/flying, SIN reiniciar el nivel.
    private func readjustSceneForCurrentSize() {
        let w = view.bounds.width
        let h = view.bounds.height
        groundY = h - 44
        anchor = CGPoint(x: max(120, view.safeAreaInsets.left + 100), y: groundY - 130)
        
        // Actualizar el límite del suelo en la colisión
        if let collision = collision {
            collision.removeBoundary(withIdentifier: "ground" as NSString)
            collision.addBoundary(withIdentifier: "ground" as NSString,
                                  from: CGPoint(x: -2000, y: groundY),
                                  to: CGPoint(x: w + 2000, y: groundY))
        }
        
        // Reposicionar los postes de la resortera
        leftPost.frame = CGRect(x: anchor.x - 18, y: anchor.y + 6, width: 10, height: groundY - anchor.y - 6)
        rightPost.frame = CGRect(x: anchor.x + 8, y: anchor.y + 6, width: 10, height: groundY - anchor.y - 6)
        
        // Reposicionar la bolita actual (si está lista)
        if let p = current, state == .ready {
            p.center = anchor
        }
        
        // Reconstruir el cielo (colinas y suelo) para el nuevo tamaño
        for sub in sky.subviews { sub.removeFromSuperview() }
        
        let hill1 = UIView(frame: CGRect(x: w * 0.05, y: groundY - 70, width: 380, height: 220))
        hill1.backgroundColor = UIColor(red: 0.45, green: 0.78, blue: 0.45, alpha: 0.6)
        hill1.layer.cornerRadius = 110
        let hill2 = UIView(frame: CGRect(x: w * 0.55, y: groundY - 100, width: 460, height: 260))
        hill2.backgroundColor = UIColor(red: 0.38, green: 0.70, blue: 0.40, alpha: 0.5)
        hill2.layer.cornerRadius = 130
        sky.addSubview(hill1)
        sky.addSubview(hill2)
        
        let ground = UIView(frame: CGRect(x: 0, y: groundY, width: w, height: h - groundY))
        ground.backgroundColor = UIColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1)
        let grass = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 12))
        grass.backgroundColor = UIColor(red: 0.30, green: 0.68, blue: 0.30, alpha: 1)
        ground.addSubview(grass)
        sky.addSubview(ground)
        
        // Reconstruir la banda elástica con la nueva posición
        updateBand()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if animator == nil {
            // Si la pantalla aún está en vertical, esperar a que rote a horizontal
            if view.bounds.width < view.bounds.height {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.viewDidAppear(animated)
                }
                return
            }
            layoutScene()
            setupPhysics()
            loadPersonImages()
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            showMenu()
            startWatchdog()
        }
    }

    // MARK: HUD
    private func setupHUD() {
        for l in [scoreLabel, levelLabel] {
            l.font = .monospacedDigitSystemFont(ofSize: 20, weight: .heavy)
            l.textColor = .white
            l.layer.shadowColor = UIColor.black.cgColor
            l.layer.shadowOpacity = 0.5
            l.layer.shadowRadius = 2
            l.layer.shadowOffset = .zero
            l.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(l)
        }
        hintLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        hintLabel.textAlignment = .center
        hintLabel.layer.shadowColor = UIColor.black.cgColor
        hintLabel.layer.shadowOpacity = 0.6
        hintLabel.layer.shadowRadius = 2
        hintLabel.layer.shadowOffset = .zero
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        restartButton.setTitle("↻", for: .normal)
        menuButton.setTitle("☰", for: .normal)
        
        // Botón de cerrar (visible tanto en menú como en partida)
        if onClose != nil {
            let closeButton = UIButton(type: .system)
            closeButton.setTitle("✕", for: .normal)
            closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
            closeButton.tintColor = .white
            closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            closeButton.layer.cornerRadius = 20
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                // Detener la partida antes de cerrar
                self.watchdog?.invalidate()
                self.animator?.removeAllBehaviors()
                self.audioPlayer?.stop()
                // Notificar a SwiftUI para cerrar
                self.onClose?()
            }, for: .touchUpInside)
            view.addSubview(closeButton)
            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        for b in [restartButton, menuButton] {
            b.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
            b.tintColor = .white
            b.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(b)
        }
        restartButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.startLevel(self.level)
        }, for: .touchUpInside)
        menuButton.addAction(UIAction { [weak self] _ in
            self?.showMenu()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            scoreLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            levelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            menuButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            menuButton.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            restartButton.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -16),
            restartButton.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor)
        ])
        updateHUD()
    }

    private func updateHUD() {
        scoreLabel.text = "⭐ \(score)"
        levelLabel.text = "Nivel \(level)"
    }

    // MARK: Escena (suelo, colinas, nubes, resortera)
    private func layoutScene() {
        let w = view.bounds.width
        let h = view.bounds.height
        groundY = h - 44
        anchor = CGPoint(x: max(170, view.safeAreaInsets.left + 150), y: groundY - 130)

        // Colinas
        let hill1 = UIView(frame: CGRect(x: w * 0.05, y: groundY - 70, width: 380, height: 220))
        hill1.backgroundColor = UIColor(red: 0.45, green: 0.78, blue: 0.45, alpha: 0.6)
        hill1.layer.cornerRadius = 110
        let hill2 = UIView(frame: CGRect(x: w * 0.55, y: groundY - 100, width: 460, height: 260))
        hill2.backgroundColor = UIColor(red: 0.38, green: 0.70, blue: 0.40, alpha: 0.5)
        hill2.layer.cornerRadius = 130
        sky.addSubview(hill1)
        sky.addSubview(hill2)

        // Nubes (animación repetida)
        for i in 0..<3 {
            let cloud = UILabel()
            cloud.text = "☁️"
            cloud.font = .systemFont(ofSize: CGFloat(44 + i * 10))
            cloud.sizeToFit()
            let y = 50 + CGFloat(i) * 55
            cloud.frame.origin = CGPoint(x: -100, y: y)
            sky.addSubview(cloud)
            UIView.animate(withDuration: 38 + Double(i) * 12, delay: -Double(i) * 14,
                           options: [.repeat, .curveLinear], animations: {
                cloud.frame.origin.x = w + 100
            }, completion: nil)
        }

        // Suelo
        let ground = UIView(frame: CGRect(x: 0, y: groundY, width: w, height: h - groundY))
        ground.backgroundColor = UIColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1)
        let grass = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 12))
        grass.backgroundColor = UIColor(red: 0.30, green: 0.68, blue: 0.30, alpha: 1)
        ground.addSubview(grass)
        sky.addSubview(ground)

        // Resortera
        for (post, dx) in [(leftPost, CGFloat(-18)), (rightPost, CGFloat(8))] {
            post.backgroundColor = UIColor(red: 0.38, green: 0.22, blue: 0.12, alpha: 1)
            post.layer.cornerRadius = 5
            post.frame = CGRect(x: anchor.x + dx, y: anchor.y + 6, width: 10, height: groundY - anchor.y - 6)
            world.addSubview(post)
        }

        // Puntos de trayectoria
        for _ in 0..<16 {
            let d = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 7))
            d.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            d.layer.cornerRadius = 3.5
            d.isHidden = true
            world.addSubview(d)
            dotViews.append(d)
        }
    }

    // MARK: Motor de física
    private func setupPhysics() {
        animator = UIDynamicAnimator(referenceView: world)

        collision = UICollisionBehavior(items: [])
        collision.collisionDelegate = self
        collision.action = { [weak self] in
            self?.tick()
        }
        collision.addBoundary(withIdentifier: "ground" as NSString,
                              from: CGPoint(x: -2000, y: groundY),
                              to: CGPoint(x: view.bounds.width + 2000, y: groundY))
        animator.addBehavior(collision)

        gravity = UIGravityBehavior(items: [])
        gravity.magnitude = 1.2
        animator.addBehavior(gravity)

        debrisBehavior = UIDynamicItemBehavior(items: [])
        debrisBehavior.allowsRotation = true
        animator.addBehavior(debrisBehavior)
    }

    @discardableResult
    private func addBody(_ v: UIView, density: CGFloat, elasticity: CGFloat, friction: CGFloat,
                         resistance: CGFloat = 0.05, angular: CGFloat = 0.3) -> UIDynamicItemBehavior {
        let b = UIDynamicItemBehavior(items: [v])
        b.density = density
        b.elasticity = elasticity
        b.friction = friction
        b.resistance = resistance
        b.angularResistance = angular
        b.allowsRotation = true
        animator.addBehavior(b)
        collision.addItem(v)
        gravity.addItem(v)
        bodies[v] = b
        lastSpeed[v] = 0
        return b
    }

    private func removeBody(_ v: UIView) {
        collision.removeItem(v)
        gravity.removeItem(v)
        if let b = bodies.removeValue(forKey: v) { animator.removeBehavior(b) }
        lastSpeed.removeValue(forKey: v)
    }

    // Impulso instantáneo (UIPushBehavior). magnitud = velocidad * masa / 100
    private func impulse(_ v: UIView, angle: CGFloat, speed: CGFloat) {
        let density = bodies[v]?.density ?? 1
        let mass = density * v.bounds.width * v.bounds.height / 10000
        let push = UIPushBehavior(items: [v], mode: .instantaneous)
        push.setAngle(angle, magnitude: speed * mass / 100)
        animator.addBehavior(push)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.animator.removeBehavior(push)
        }
    }

    // MARK: Fotos de personas
    private func loadPersonImages() {
        var urls: [URL] = []
        let subs: [String?] = [nil, "Personas"]
        for sub in subs {
            urls += Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: sub) ?? []
            urls += Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: sub) ?? []
        }
        let files = urls.filter { $0.lastPathComponent.hasPrefix("persona_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var seen = Set<String>()
        for u in files where !seen.contains(u.lastPathComponent) {
            seen.insert(u.lastPathComponent)
            if let img = UIImage(contentsOfFile: u.path) {
                personImages.append(circular(img, size: 96))
                personNames.append(u.deletingPathExtension().lastPathComponent)
            }
        }
        if personImages.isEmpty { personImages = fallbackFaces() }
    }

    private func circular(_ img: UIImage, size: CGFloat) -> UIImage {
        let r = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return r.image { _ in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            UIBezierPath(ovalIn: rect).addClip()
            let s = max(size / img.size.width, size / img.size.height)
            let w = img.size.width * s
            let h = img.size.height * s
            img.draw(in: CGRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h))
        }
    }

    private func fallbackFaces() -> [UIImage] {
        let faces = ["😀", "😎", "🤓", "🥳", "😜", "🤠"]
        let colors: [UIColor] = [.systemYellow, .systemTeal, .systemPink, .systemPurple, .systemGreen, .systemOrange]
        var out: [UIImage] = []
        for (i, f) in faces.enumerated() {
            let r = UIGraphicsImageRenderer(size: CGSize(width: 96, height: 96))
            out.append(r.image { _ in
                colors[i].setFill()
                UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 96, height: 96)).fill()
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 58)]
                let s = (f as NSString).size(withAttributes: attrs)
                (f as NSString).draw(at: CGPoint(x: (96 - s.width) / 2, y: (96 - s.height) / 2), withAttributes: attrs)
            })
        }
        return out
    }

    // MARK: Niveles
    private func levelQueue(_ n: Int) -> [Kind] {
        switch n {
        case 1: return [.normal, .normal, .heavy, .normal]
        case 2: return [.normal, .split, .heavy, .dash, .normal]
        case 3: return [.normal, .split, .dash, .heavy, .normal, .normal]
        case 4: return [.heavy, .split, .dash, .normal, .heavy, .normal]
        case 5: return [.split, .dash, .heavy, .normal, .split, .normal]
        case 6: return [.heavy, .split, .dash, .normal, .heavy, .split, .dash]
        case 7: return [.normal, .heavy, .split, .dash, .heavy, .normal, .normal, .split]
        case 8: return [.split, .dash, .heavy, .normal, .heavy, .split, .dash, .heavy]
        case 9: return [.heavy, .heavy, .split, .dash, .normal, .normal, .split, .dash, .heavy]
        case 10: return [.dash, .split, .heavy, .normal, .heavy, .split, .dash, .normal, .heavy, .split]
        case 11: return [.heavy, .split, .dash, .normal, .heavy, .split, .dash, .normal, .heavy, .split, .normal]
        case 12: return [.normal, .heavy, .split, .dash, .heavy, .split, .dash, .normal, .heavy, .split, .dash, .heavy]
        case 13: return [.split, .dash, .heavy, .normal, .heavy, .split, .dash, .normal, .heavy, .split, .dash, .heavy, .normal]
        case 14: return [.heavy, .heavy, .split, .dash, .normal, .heavy, .split, .dash, .normal, .heavy, .split, .dash, .heavy, .normal]
        default: return [.dash, .split, .heavy, .normal, .heavy, .split, .dash, .normal, .heavy, .split, .dash, .heavy, .normal, .heavy, .split]
        }
    }

    private func buildLevel(_ n: Int) {
        // La base se aleja más en niveles altos
        let base = view.bounds.width * (0.64 + CGFloat(min(n, 15)) * 0.02)
        
        switch n {
        case 1:
            tower(cx: base, bottom: groundY, pillar: .wood, plank: .wood, rival: true)
            addRival(cx: base + 125, bottom: groundY)
        case 2:
            tower(cx: base - 40, bottom: groundY, pillar: .glass, plank: .wood, rival: true)
            tower(cx: base + 110, bottom: groundY, pillar: .stone, plank: .wood, rival: true)
            addBlock(.wood, cx: base + 35, bottom: groundY, w: 150, h: 20)
            addRival(cx: base + 35, bottom: groundY - 20)
        case 3:
            let top = tower(cx: base - 80, bottom: groundY, pillar: .wood, plank: .glass, rival: false)
            tower(cx: base - 80, bottom: top, pillar: .stone, plank: .wood, rival: true)
            tower(cx: base + 50, bottom: groundY, pillar: .glass, plank: .stone, rival: true)
            addBlock(.stone, cx: base - 140, bottom: groundY, w: 50, h: 100)
            addRival(cx: base + 180, bottom: groundY)
        case 4:
            tower(cx: base - 100, bottom: groundY, pillar: .glass, plank: .wood, rival: true)
            tower(cx: base + 60, bottom: groundY, pillar: .stone, plank: .glass, rival: true)
            addBlock(.wood, cx: base - 20, bottom: groundY, w: 30, h: 120)
            addRival(cx: base - 20, bottom: groundY + 20)
            addRival(cx: base + 200, bottom: groundY)
        case 5:
            let top1 = tower(cx: base - 120, bottom: groundY, pillar: .stone, plank: .wood, rival: false)
            tower(cx: base - 120, bottom: top1, pillar: .wood, plank: .glass, rival: true)
            tower(cx: base, bottom: groundY, pillar: .glass, plank: .stone, rival: true)
            tower(cx: base + 120, bottom: groundY, pillar: .wood, plank: .stone, rival: true)
            addRival(cx: base + 240, bottom: groundY)
        case 6:
            tower(cx: base - 150, bottom: groundY, pillar: .wood, plank: .wood, rival: true)
            tower(cx: base - 20, bottom: groundY, pillar: .stone, plank: .glass, rival: true)
            tower(cx: base + 110, bottom: groundY, pillar: .glass, plank: .stone, rival: true)
            addBlock(.stone, cx: base + 50, bottom: groundY, w: 40, h: 150)
            addRival(cx: base + 250, bottom: groundY)
            addRival(cx: base - 200, bottom: groundY)
        case 7:
            let top1 = tower(cx: base - 100, bottom: groundY, pillar: .glass, plank: .wood, rival: false)
            tower(cx: base - 100, bottom: top1, pillar: .stone, plank: .glass, rival: true)
            tower(cx: base + 50, bottom: groundY, pillar: .wood, plank: .stone, rival: true)
            tower(cx: base + 180, bottom: groundY, pillar: .glass, plank: .wood, rival: true)
            addRival(cx: base - 220, bottom: groundY)
            addRival(cx: base + 300, bottom: groundY)
        case 8:
            tower(cx: base - 140, bottom: groundY, pillar: .stone, plank: .wood, rival: true)
            tower(cx: base, bottom: groundY, pillar: .wood, plank: .glass, rival: true)
            tower(cx: base + 140, bottom: groundY, pillar: .glass, plank: .stone, rival: true)
            addBlock(.stone, cx: base - 70, bottom: groundY, w: 40, h: 180)
            addRival(cx: base + 260, bottom: groundY)
            addRival(cx: base - 260, bottom: groundY)
        case 9:
            let top = tower(cx: base - 100, bottom: groundY, pillar: .wood, plank: .stone, rival: false)
            tower(cx: base - 100, bottom: top, pillar: .glass, plank: .wood, rival: true)
            tower(cx: base + 50, bottom: groundY, pillar: .stone, plank: .glass, rival: true)
            addRival(cx: base + 200, bottom: groundY)
            addRival(cx: base - 240, bottom: groundY)
            addRival(cx: base + 320, bottom: groundY)
        case 10:
            tower(cx: base - 180, bottom: groundY, pillar: .glass, plank: .wood, rival: true)
            tower(cx: base - 50, bottom: groundY, pillar: .stone, plank: .glass, rival: true)
            tower(cx: base + 80, bottom: groundY, pillar: .wood, plank: .stone, rival: true)
            addBlock(.stone, cx: base - 120, bottom: groundY, w: 50, h: 200)
            addRival(cx: base + 220, bottom: groundY)
            addRival(cx: base - 300, bottom: groundY)
        default:
            let topLeft = tower(cx: base - 200, bottom: groundY, pillar: .stone, plank: .wood, rival: false)
            tower(cx: base - 200, bottom: topLeft, pillar: .wood, plank: .glass, rival: true)
            let topMid = tower(cx: base - 60, bottom: groundY, pillar: .glass, plank: .stone, rival: false)
            tower(cx: base - 60, bottom: topMid, pillar: .stone, plank: .wood, rival: true)
            tower(cx: base + 100, bottom: groundY, pillar: .wood, plank: .glass, rival: true)
            addBlock(.stone, cx: base + 30, bottom: groundY, w: 60, h: 250)
            addBlock(.wood, cx: base - 150, bottom: groundY, w: 40, h: 180)
            addRival(cx: base + 240, bottom: groundY)
            addRival(cx: base + 320, bottom: groundY)
            addRival(cx: base - 320, bottom: groundY)
            addRival(cx: base - 400, bottom: groundY)
        }
    }

    @discardableResult
    private func tower(cx: CGFloat, bottom: CGFloat, pillar: Mat, plank: Mat, rival: Bool) -> CGFloat {
        let ph: CGFloat = 60
        let pw: CGFloat = 16
        let th: CGFloat = 14
        addBlock(pillar, cx: cx - 36, bottom: bottom, w: pw, h: ph)
        addBlock(pillar, cx: cx + 36, bottom: bottom, w: pw, h: ph)
        addBlock(plank, cx: cx, bottom: bottom - ph, w: 104, h: th)
        let top = bottom - ph - th
        if rival { addRival(cx: cx, bottom: top) }
        return top
    }

    private func addBlock(_ m: Mat, cx: CGFloat, bottom: CGFloat, w: CGFloat, h: CGFloat) {
        let b = BlockView(frame: CGRect(x: cx - w / 2, y: bottom - h, width: w, height: h))
        b.material = m
        b.hp = m.hp
        b.points = m.points
        b.backgroundColor = m.color
        b.layer.cornerRadius = 3
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.black.withAlphaComponent(0.25).cgColor
        world.addSubview(b)
        blocks.append(b)
    }

    private func addRival(cx: CGFloat, bottom: CGFloat) {
        let r = RivalView(frame: CGRect(x: cx - rivalSize / 2, y: bottom - rivalSize, width: rivalSize, height: rivalSize))
        r.isRival = true
        r.hp = 2
        r.points = 200
        r.backgroundColor = .systemGreen
        r.layer.cornerRadius = rivalSize / 2
        r.layer.borderWidth = 2
        r.layer.borderColor = UIColor.white.cgColor
        let l = UILabel(frame: r.bounds)
        l.text = "😠"
        l.font = .systemFont(ofSize: 22)
        l.textAlignment = .center
        r.addSubview(l)
        world.addSubview(r)
        rivals.append(r)
    }

    // Los bloques son vistas estáticas hasta el primer lanzamiento
    private func activateWorld() {
        guard !worldActive else { return }
        worldActive = true
        for b in blocks {
            addBody(b, density: b.material.density, elasticity: 0.15, friction: 0.7, resistance: 0.2, angular: 0.4)
        }
        for r in rivals {
            addBody(r, density: 1.2, elasticity: 0.2, friction: 0.6, resistance: 0.2, angular: 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.armed = true
        }
    }

    private func clearWorld() {
        hideTrajectory()
        for v in Array(bodies.keys) { removeBody(v) }
        for b in blocks { b.removeFromSuperview() }
        for r in rivals { r.removeFromSuperview() }
        for p in flying { p.removeFromSuperview() }
        current?.removeFromSuperview()
        for q in queueViews { q.removeFromSuperview() }
        blocks.removeAll()
        rivals.removeAll()
        flying.removeAll()
        queueViews.removeAll()
        current = nil
        finishScheduled = false
        restSince = nil
        dragging = false
    }

    private func loadScene(_ n: Int) {
        clearWorld()
        sceneToken += 1
        level = n
        score = 0
        armed = false
        worldActive = false
        queue = levelQueue(n)
        buildLevel(n)
        updateHUD()
        state = .ready
        loadNextProjectile()
        updateBand()
    }

    private func startLevel(_ n: Int) {
        hideOverlay()
        loadScene(n)
    }

    // MARK: Proyectiles
    private func makeProjectile(kind: Kind, template: ProjectileView? = nil) -> ProjectileView {
        let img: UIImage
        let name: String
        if let t = template, let ti = t.image {
            img = ti
            name = t.personName
        } else {
            let idx = personIndex % personImages.count
            img = personImages[idx]
            name = personNames.indices.contains(idx) ? personNames[idx] : ""
            personIndex += 1
        }
        let p = ProjectileView(image: img)
        p.personName = name
        p.kind = kind
        p.frame = CGRect(x: 0, y: 0, width: kind.size, height: kind.size)
        p.contentMode = .scaleAspectFill
        p.clipsToBounds = true
        p.layer.cornerRadius = kind.size / 2
        p.layer.borderWidth = 3
        p.layer.borderColor = kind.color.cgColor
        return p
    }

    private func loadNextProjectile() {
        guard !queue.isEmpty else { return }
        let kind = queue.removeFirst()
        let p = makeProjectile(kind: kind)
        p.center = CGPoint(x: anchor.x - 90, y: groundY - kind.size / 2)
        p.alpha = 0
        world.addSubview(p)
        current = p
        state = .ready
        hintLabel.text = kind.hint
        updateQueue()
        updateBand()
        UIView.animate(withDuration: 0.6, delay: 0,
                       usingSpringWithDamping: 0.55, initialSpringVelocity: 0.8,
                       options: [], animations: {
            p.center = self.anchor
            p.alpha = 1
        }, completion: { _ in
            self.updateBand()
        })
    }

    private func updateQueue() {
        for q in queueViews { q.removeFromSuperview() }
        queueViews.removeAll()
        let size: CGFloat = 22
        let count = max(queue.count, 1)
        let avail = view.bounds.width * 0.28
        let step = min(size + 6, avail / CGFloat(count))
        let y = view.safeAreaInsets.top + 44
        for (i, k) in queue.enumerated() {
            let img = personImages[(personIndex + i) % personImages.count]
            let v = UIImageView(image: img)
            v.frame = CGRect(x: view.safeAreaInsets.left + 16 + CGFloat(i) * step, y: y, width: size, height: size)
            v.layer.cornerRadius = size / 2
            v.clipsToBounds = true
            v.layer.borderWidth = 2
            v.layer.borderColor = k.color.cgColor
            view.addSubview(v)
            queueViews.append(v)
        }
    }

    private func updateBand() {
        let rest = CGPoint(x: anchor.x, y: anchor.y + 8)
        var target = rest
        if state == .ready, let c = current { target = c.center }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: anchor.x - 13, y: anchor.y + 8))
        path.addLine(to: target)
        path.move(to: CGPoint(x: anchor.x + 13, y: anchor.y + 8))
        path.addLine(to: target)
        bandLayer.path = path.cgPath
    }

    private func showTrajectory(from c: CGPoint) {
        let vx = (anchor.x - c.x) * speedFactor
        let vy = (anchor.y - c.y) * speedFactor
        let g = gravity.magnitude * 1000
        for (i, d) in dotViews.enumerated() {
            let t = CGFloat(i + 1) * 0.07
            d.center = CGPoint(x: c.x + vx * t, y: c.y + vy * t + 0.5 * g * t * t)
            d.alpha = 1 - CGFloat(i) / CGFloat(dotViews.count)
            d.isHidden = false
        }
    }

    private func hideTrajectory() {
        for d in dotViews { d.isHidden = true }
    }

    // MARK: Gestos
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard state == .ready, let p = current else { return }
        let loc = g.location(in: world)
        switch g.state {
        case .began:
            dragging = hypot(loc.x - p.center.x, loc.y - p.center.y) < 90
        case .changed:
            guard dragging else { return }
            var dx = loc.x - anchor.x
            var dy = loc.y - anchor.y
            let d = hypot(dx, dy)
            if d > maxStretch {
                dx *= maxStretch / d
                dy *= maxStretch / d
            }
            var c = CGPoint(x: anchor.x + dx, y: anchor.y + dy)
            c.y = min(c.y, groundY - p.bounds.height / 2)
            p.center = c
            updateBand()
            showTrajectory(from: c)
        case .ended, .cancelled:
            guard dragging else { return }
            dragging = false
            hideTrajectory()
            let stretch = hypot(p.center.x - anchor.x, p.center.y - anchor.y)
            if stretch > 25 && g.state == .ended {
                launch(p)
            } else {
                UIView.animate(withDuration: 0.4, delay: 0,
                               usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8,
                               options: [], animations: {
                    p.center = self.anchor
                }, completion: { _ in self.updateBand() })
                updateBand()
            }
        default:
            break
        }
    }

    @objc private func handleTap() {
        if state == .flying { useAbility() }
    }

    // MARK: Lanzamiento y habilidades
    private func launch(_ p: ProjectileView) {
        guard state == .ready, current === p, !p.launched, bodies[p] == nil else { return }
        p.launched = true
        activateWorld()
        state = .flying
        current = nil
        abilityUsed = false
        restSince = nil
        launchTime = Date()
        addBody(p, density: p.kind.density, elasticity: 0.45, friction: 0.6)
        flying = [p]

        let dx = anchor.x - p.center.x
        let dy = anchor.y - p.center.y
        let stretch = hypot(dx, dy)
        impulse(p, angle: atan2(dy, dx), speed: stretch * speedFactor)

        playPersona(p.personName)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        hintLabel.text = (p.kind == .normal) ? "" : "¡Toca la pantalla para usar el poder!"
        updateBand()
    }

    private func playPersona(_ name: String) {
        audioPlayer?.stop()
        audioPlayer = nil
        guard !name.isEmpty else { return }
        let url = Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Personas")
        guard let u = url else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: u)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }

    private func useAbility() {
        guard state == .flying, !abilityUsed, let p = flying.first, p.superview != nil,
              let b = bodies[p] else { return }
        let vel = b.linearVelocity(for: p)
        switch p.kind {
        case .normal:
            return
        case .heavy:
            abilityUsed = true
            impulse(p, angle: .pi / 2, speed: 1000)
        case .dash:
            abilityUsed = true
            impulse(p, angle: atan2(vel.y, vel.x), speed: 700)
        case .split:
            abilityUsed = true
            let base = atan2(vel.y, vel.x)
            let sp = max(hypot(vel.x, vel.y), 500)
            for da in [CGFloat(-0.28), CGFloat(0.28)] {
                let c = makeProjectile(kind: .split, template: p)
                c.launched = true
                c.center = p.center
                world.addSubview(c)
                let cb = addBody(c, density: 1, elasticity: 0.45, friction: 0.6)
                cb.addLinearVelocity(CGPoint(x: cos(base + da) * sp, y: sin(base + da) * sp), for: c)
                flying.append(c)
            }
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        // Pulso con keyframes (solo opacidad para no interferir con la física)
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) { p.alpha = 0.4 }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { p.alpha = 1 }
        }, completion: nil)
    }

    // MARK: Paso de simulación (action del UICollisionBehavior)
    // OJO: UIDynamicAnimator se duerme cuando todo queda quieto y deja de llamar a este
    // action; por eso la lógica de turnos vive en checkTurn (Timer), no aquí.
    private func tick() {
        for (v, b) in bodies {
            let vel = b.linearVelocity(for: v)
            lastSpeed[v] = hypot(vel.x, vel.y)
        }
    }

    // MARK: Vigilante de turnos (10 veces por segundo)
    private func startWatchdog() {
        watchdog?.invalidate()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkTurn()
        }
        RunLoop.main.add(t, forMode: .common)
        watchdog = t
    }

    deinit { watchdog?.invalidate() }

    private func checkTurn() {
        guard animator != nil, (state == .ready || state == .flying) else { return }
        let w = view.bounds.width
        let h = view.bounds.height

        // Limpieza de lo que salió del mundo
        for r in rivals where r.frame.maxX < -50 || r.frame.minX > w + 50 || r.frame.minY > h + 50 {
            destroy(r)
        }
        for b in blocks where b.frame.maxX < -300 || b.frame.minX > w + 300 || b.frame.minY > h + 300 {
            b.isDead = true
            removeBody(b)
            blocks.removeAll { $0 === b }
            b.removeFromSuperview()
        }
        for p in flying where p.center.x < -100 || p.center.x > w + 100 || p.center.y > h + 100 {
            retire(p)
        }

        // Victoria: ya no quedan enemigos registrados
        // SOLO verificar victoria si el nivel está activo (no en menú ni en ended)
        guard state == .ready || state == .flying else { return }
        if rivals.isEmpty { levelWon(); return }
        guard state == .flying else { return }

        // Fin del turno: todo quieto durante un rato, o tiempo máximo de seguridad
        let elapsed = Date().timeIntervalSince(launchTime)
        var moving = false
        for (v, b) in bodies {
            let vel = b.linearVelocity(for: v)
            if hypot(vel.x, vel.y) > 25 { moving = true; break }
        }
        var shouldFinish = elapsed > 8
        if !moving && elapsed > 0.8 {
            if restSince == nil {
                restSince = Date()
            } else if Date().timeIntervalSince(restSince!) > 1.0 {
                shouldFinish = true
            }
        } else {
            restSince = nil
        }
        if shouldFinish { finishShot() }
    }

    private func retire(_ p: ProjectileView) {
        guard flying.contains(where: { $0 === p }) else { return }
        removeBody(p)
        flying.removeAll { $0 === p }
        UIView.animate(withDuration: 0.3, animations: { p.alpha = 0 }, completion: { _ in
            p.removeFromSuperview()
        })
    }

    private func finishShot() {
        guard state == .flying else { return }
        state = .resolving
        for p in flying { retire(p) }
        if rivals.isEmpty {
            levelWon()
        } else if queue.isEmpty {
            state = .ended
            showLose()
        } else {
            loadNextProjectile()   // deja el estado en .ready
        }
    }

    // MARK: Delegado de colisiones
    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item1: UIDynamicItem,
                           with item2: UIDynamicItem,
                           at p: CGPoint) {
        DispatchQueue.main.async {
            self.handleImpact(item1, item2)
        }
    }

    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at p: CGPoint) {
        DispatchQueue.main.async {
            self.handleGroundImpact(item)
        }
    }

    private func handleImpact(_ a: UIDynamicItem, _ b: UIDynamicItem) {
        guard armed, state != .menu, let va = a as? UIView, let vb = b as? UIView else { return }
        let impact = max(lastSpeed[va] ?? 0, lastSpeed[vb] ?? 0)
        guard impact > 140 else { return }
        let dmg = (impact - 120) / 130
        if let d = va as? DamageView {
            applyDamage(d, dmg * ((vb as? ProjectileView)?.kind.damage ?? 1))
        }
        if let d = vb as? DamageView {
            applyDamage(d, dmg * ((va as? ProjectileView)?.kind.damage ?? 1))
        }
    }

    private func handleGroundImpact(_ item: UIDynamicItem) {
        guard armed, let v = item as? DamageView else { return }
        let impact = lastSpeed[v] ?? 0
        guard impact > 380 else { return }
        applyDamage(v, (impact - 250) / 130)
    }

    private func applyDamage(_ d: DamageView, _ dmg: CGFloat) {
        guard !d.isDead, d.superview != nil, dmg > 0 else { return }
        d.hp -= dmg
        if d.hp <= 0 {
            destroy(d)
        } else {
            UIView.animateKeyframes(withDuration: 0.25, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) { d.alpha = 0.5 }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { d.alpha = 1 }
            }, completion: nil)
        }
    }

    private func destroy(_ d: DamageView) {
        guard !d.isDead, d.superview != nil else { return }
        d.isDead = true
        removeBody(d)
        blocks.removeAll { $0 === d }
        rivals.removeAll { $0 === d }
        score += d.points
        updateHUD()

        var color = UIColor.systemGreen
        if let b = d as? BlockView { color = b.material.color }
        spawnDebris(at: d.center, color: color, count: d.isRival ? 14 : 8)
        floatingText("+\(d.points)", at: d.center)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(withDuration: 0.15, animations: {
            d.alpha = 0
            d.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        }, completion: { _ in
            d.removeFromSuperview()
        })

        if d.isRival {
            shakeWorld()
            if rivals.isEmpty { levelWon() }
        }
    }

    // MARK: Efectos
    private func spawnDebris(at c: CGPoint, color: UIColor, count: Int) {
        for _ in 0..<count {
            let d = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 7))
            d.backgroundColor = color
            d.center = c
            world.addSubview(d)
            gravity.addItem(d)
            debrisBehavior.addItem(d)
            debrisBehavior.addAngularVelocity(CGFloat.random(in: -10...10), for: d)
            let push = UIPushBehavior(items: [d], mode: .instantaneous)
            push.setAngle(CGFloat.random(in: -CGFloat.pi...0), magnitude: CGFloat.random(in: 0.01...0.025))
            animator.addBehavior(push)
            UIView.animate(withDuration: 0.6, delay: 0.3, options: [], animations: {
                d.alpha = 0
            }, completion: { _ in
                self.gravity.removeItem(d)
                self.debrisBehavior.removeItem(d)
                self.animator.removeBehavior(push)
                d.removeFromSuperview()
            })
        }
    }

    private func floatingText(_ text: String, at c: CGPoint) {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 20, weight: .heavy)
        l.textColor = .systemYellow
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowOpacity = 0.7
        l.layer.shadowRadius = 2
        l.layer.shadowOffset = .zero
        l.sizeToFit()
        l.center = c
        world.addSubview(l)
        UIView.animateKeyframes(withDuration: 0.9, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                l.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                l.transform = CGAffineTransform(translationX: 0, y: -50)
                l.alpha = 0
            }
        }, completion: { _ in l.removeFromSuperview() })
    }

    private func shakeWorld() {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: [], animations: {
            let offsets: [CGFloat] = [-8, 8, -5, 5, 0]
            for (i, dx) in offsets.enumerated() {
                UIView.addKeyframe(withRelativeStartTime: Double(i) / 5, relativeDuration: 0.2) {
                    self.world.transform = CGAffineTransform(translationX: dx, y: 0)
                }
            }
        }, completion: nil)
    }

    // MARK: Fin de nivel
    private func levelWon() {
        guard state != .ended, state != .menu else { return }
        // NUNCA declarar victoria si el nivel aún no se ha jugado
        guard state == .flying || state == .resolving else { return }
        // NUNCA declarar victoria si quedan rivales en el array
        guard rivals.isEmpty else { return }
        state = .ended
        hintLabel.text = ""
        let token = sceneToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, token == self.sceneToken, self.state == .ended else { return }
            self.showWin()
        }
    }

    private func starsText(_ n: Int) -> String {
        return String(repeating: "★", count: n) + String(repeating: "☆", count: max(0, 3 - n))
    }

    private func showWin() {
        let remaining = queue.count
        let stars = remaining >= 2 ? 3 : (remaining == 1 ? 2 : 1)
        let d = UserDefaults.standard
        if stars > d.integer(forKey: "stars_\(level)") { d.set(stars, forKey: "stars_\(level)") }
        if score > d.integer(forKey: "best_\(level)") { d.set(score, forKey: "best_\(level)") }
        if level > d.integer(forKey: "unlocked_level") { d.set(level, forKey: "unlocked_level") }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        var buttons: [UIButton] = []
        if level < 15 {
            buttons.append(makeButton("Siguiente nivel ▶︎") { self.startLevel(self.level + 1) })
        }
        buttons.append(makeButton("Repetir", color: .systemBlue) { self.startLevel(self.level) })
        buttons.append(makeButton("Menú", color: .systemGray) { self.showMenu() })
        let title = level < 15 ? "¡Nivel \(level) completado!" : "¡Completaste todo! 🎉"
        showOverlay(title: title,
                    subtitle: "\(starsText(stars))\nPuntos: \(score) · Récord: \(d.integer(forKey: "best_\(level)"))",
                    buttons: buttons)
    }

    private func showLose() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        let buttons = [
            makeButton("Reintentar") { self.startLevel(self.level) },
            makeButton("Menú", color: .systemGray) { self.showMenu() }
        ]
        showOverlay(title: "¡Se acabaron las personas!", subtitle: "Puntos: \(score)", buttons: buttons)
    }

    private func showMenu() {
        loadScene(1)
        state = .menu
        hintLabel.text = ""
        
        let unlockedLevels = UserDefaults.standard.integer(forKey: "unlocked_level")
        
        var arranged: [UIView] = []
        
        let titleLabel = UILabel()
        titleLabel.text = "MAPA DE NIVELES"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        arranged.append(titleLabel)
        
        // Grid horizontal: 5 columnas x 3 filas
        var gridRows: [UIStackView] = []
        var currentRowButtons: [UIView] = []
        
        for n in 1...15 {
            let isUnlocked = (n <= unlockedLevels + 1)
            
            let btn = UIButton(type: .system)
            var cfg = UIButton.Configuration.filled()
            cfg.title = isUnlocked ? "\(n)" : "🔒"
            if isUnlocked {
                cfg.subtitle = starsText(UserDefaults.standard.integer(forKey: "stars_\(n)"))
                cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
                    var c = c
                    c.font = UIFont.systemFont(ofSize: 10, weight: .bold)
                    return c
                }
            }
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
                var c = c
                c.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
                return c
            }
            cfg.baseBackgroundColor = isUnlocked ? .systemOrange : .systemGray
            cfg.baseForegroundColor = .white
            cfg.cornerStyle = .capsule
            btn.configuration = cfg
            btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
            
            btn.widthAnchor.constraint(equalToConstant: 66).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 66).isActive = true
            
            if isUnlocked {
                btn.addAction(UIAction { [weak self] _ in
                    self?.hideOverlay()
                    self?.startLevel(n)
                }, for: .touchUpInside)
            } else {
                btn.isUserInteractionEnabled = false
            }
            
            currentRowButtons.append(btn)
            
            if currentRowButtons.count == 5 || n == 15 {
                let rowStack = UIStackView(arrangedSubviews: currentRowButtons)
                rowStack.axis = .horizontal
                rowStack.spacing = 12
                rowStack.alignment = .center
                rowStack.distribution = .equalSpacing
                gridRows.append(rowStack)
                currentRowButtons = []
            }
        }
        
        for row in gridRows {
            arranged.append(row)
        }
        
        showOverlayCustom(arranged: arranged)
    }
    
    private func showOverlayCustom(arranged: [UIView]) {
        hideOverlay()
        let o = UIView(frame: view.bounds)
        o.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        o.backgroundColor = UIColor.black.withAlphaComponent(0.55)

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        o.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: o.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: o.centerYAnchor)
        ])
        view.addSubview(o)
        overlay = o

        o.alpha = 0
        stack.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.55, initialSpringVelocity: 0.6,
                       options: [], animations: {
            o.alpha = 1
            stack.transform = .identity
        }, completion: nil)
    }

    // MARK: Overlay (menús) con animación spring
    private func makeButton(_ title: String, color: UIColor = .systemOrange, action: @escaping () -> Void) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseBackgroundColor = color
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
            var c = c
            c.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            return c
        }
        let b = UIButton(configuration: cfg)
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        b.widthAnchor.constraint(equalToConstant: 240).isActive = true
        return b
    }

    private func showOverlay(title: String, subtitle: String, buttons: [UIButton], wobble: Bool = false) {
        hideOverlay()
        let o = UIView(frame: view.bounds)
        o.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        o.backgroundColor = UIColor.black.withAlphaComponent(0.55)

        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 32, weight: .heavy)
        t.textColor = .white
        t.textAlignment = .center
        t.numberOfLines = 0

        let s = UILabel()
        s.text = subtitle
        s.font = .systemFont(ofSize: 16, weight: .medium)
        s.textColor = UIColor.white.withAlphaComponent(0.9)
        s.textAlignment = .center
        s.numberOfLines = 0

        var arranged: [UIView] = [t, s]
        arranged += buttons
        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        o.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: o.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: o.centerYAnchor)
        ])
        view.addSubview(o)
        overlay = o

        o.alpha = 0
        stack.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.55, initialSpringVelocity: 0.6,
                       options: [], animations: {
            o.alpha = 1
            stack.transform = .identity
        }, completion: nil)

        if wobble {
            UIView.animateKeyframes(withDuration: 1.6, delay: 0.5, options: [.repeat, .autoreverse], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    t.transform = CGAffineTransform(rotationAngle: 0.05)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    t.transform = CGAffineTransform(rotationAngle: -0.05)
                }
            }, completion: nil)
        }
    }

    private func hideOverlay() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}
