import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }

    static func adaptable(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum AppColors {
    static let primary    = Color.adaptable(light: 0xC41E24, dark: 0xE8454A)
    static let texto      = Color.adaptable(light: 0x2D2420, dark: 0xF5EEE7)   // antes: dark
    static let gris       = Color.adaptable(light: 0x8B7E74, dark: 0xB5A99E)   // antes: gray
    static let grisClaro  = Color.adaptable(light: 0xB8AFA6, dark: 0x6F655D)   // antes: lightGray
    static let bg         = Color.adaptable(light: 0xF8F3EC, dark: 0x1A1512)
    static let surface    = Color.adaptable(light: 0xFFFFFF, dark: 0x2A221D)
    static let hairline   = Color.adaptable(light: 0xEDE5DA, dark: 0x3A302A)
    static let success    = Color(hex: 0x27AE60)
    static let warning    = Color(hex: 0xF39C12)
    static let danger     = Color(hex: 0xE74C3C)
    static let gold       = Color(hex: 0xF5A623)
}

extension Font {
    /// Reemplaza a Cormorant Garamond: serif nativo (New York), escala con Dynamic Type.
    static let tituloMarca = Font.system(.title, design: .serif, weight: .bold)
}

/// Unifica los mapas de estados que estaban duplicados en theme.dart y en los 2 widgets de seguimiento.
enum EstadoPedidoUI {
    static func color(_ e: String) -> Color {
        switch e {
        case "PENDIENTE_PAGO": AppColors.warning
        case "CONFIRMADO": Color(hex: 0x3498DB)
        case "EN_PREPARACION": Color(hex: 0xE67E22)
        case "EN_CAMINO": AppColors.primary
        case "ENTREGADO": AppColors.success
        case "CANCELADO": AppColors.danger
        default: AppColors.gris
        }
    }
    static func etiqueta(_ e: String) -> String {
        switch e {
        case "PENDIENTE_PAGO": "Pendiente de pago"
        case "CONFIRMADO": "Confirmado"
        case "EN_PREPARACION": "En preparación"
        case "EN_CAMINO": "En camino"
        case "ENTREGADO": "Entregado"
        case "CANCELADO": "Cancelado"
        default: e
        }
    }
    static func titulo(_ e: String) -> String {
        switch e {
        case "CONFIRMADO": "Pedido confirmado"
        case "EN_PREPARACION": "Preparando tu pedido"
        case "CANCELADO": "Pedido cancelado"
        default: etiqueta(e)
        }
    }
    static func subtitulo(_ e: String) -> String {
        switch e {
        case "PENDIENTE_PAGO": "Estamos esperando tu pago"
        case "CONFIRMADO": "Recibimos tu pedido"
        case "EN_PREPARACION": "Tu pizza está en el horno"
        case "EN_CAMINO": "Tu pedido está en camino"
        case "ENTREGADO": "¡Buen provecho!"
        case "CANCELADO": "Este pedido fue cancelado"
        default: ""
        }
    }
    /// SF Symbols (no existe un símbolo de pizza; puedes importar uno propio con "Custom Symbols").
    static func icono(_ e: String) -> String {
        switch e {
        case "PENDIENTE_PAGO": "hourglass"
        case "CONFIRMADO": "receipt"
        case "EN_PREPARACION": "flame.fill"
        case "EN_CAMINO": "scooter"
        case "ENTREGADO": "checkmark.circle"
        case "CANCELADO": "xmark"
        default: "receipt"
        }
    }
}
