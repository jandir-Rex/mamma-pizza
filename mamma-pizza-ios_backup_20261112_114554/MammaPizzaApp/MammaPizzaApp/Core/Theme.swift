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
    // --- Marca ---
    static let primary      = Color.adaptable(light: 0x8B3A2E, dark: 0xC65A44)
    static let cacao        = Color(hex: 0x5E3526)          // fijo: fondos de marca
    static let cacaoOscuro  = Color(hex: 0x3E2118)          // fijo
    static let kraft        = Color(hex: 0xE9CFA6)          // fijo
    static let kraftClaro   = Color.adaptable(light: 0xF3E3C8, dark: 0x3A2E22)
    static let cacaoTexto   = Color.adaptable(light: 0x5E3526, dark: 0xE9CFA6) // texto/íconos sobre kraftClaro

    // --- Acentos ---
    static let tomate       = Color.adaptable(light: 0xE02B20, dark: 0xFF6A5C)
    static let albahaca     = Color(hex: 0x3C9A4A)
    static let mostaza      = Color(hex: 0xF2B233)
    static let mostazaTexto = Color.adaptable(light: 0x8A5B00, dark: 0xF2B233)
    static let info         = Color.adaptable(light: 0x1F6FBF, dark: 0x6AAEF0)
    static let naranja      = Color.adaptable(light: 0xC2570C, dark: 0xFF9A55)
    static let morado       = Color.adaptable(light: 0x6B4BB8, dark: 0xA78BFA)

    // --- Base ---
    static let texto     = Color.adaptable(light: 0x2B2118, dark: 0xF5EEE7)
    static let gris      = Color.adaptable(light: 0x7A7168, dark: 0xB5A99E)
    static let grisClaro = Color.adaptable(light: 0xB8AFA6, dark: 0x6F655D)
    static let bg        = Color.adaptable(light: 0xFBF6EE, dark: 0x1A1512)
    static let surface   = Color.adaptable(light: 0xFFFFFF, dark: 0x2A221D)
    static let hairline  = Color.adaptable(light: 0xE8E2DA, dark: 0x3A302A)

    // --- Semánticos ---
    static let success = Color.adaptable(light: 0x2E7D3A, dark: 0x5FBF6E)
    static let warning = mostaza
    static let danger  = Color.adaptable(light: 0xC0392B, dark: 0xFF7A6B)
    static let gold    = mostaza

    // --- Degradado de marca ---
    static let marcaDegradado = LinearGradient(colors: [cacao, cacaoOscuro],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Font {
    /// Títulos de marca: serif nativo (New York), escala con Dynamic Type.
    static let tituloMarca = Font.system(.title, design: .serif, weight: .bold)
    static func marca(_ estilo: Font.TextStyle = .largeTitle) -> Font {
        .system(estilo, design: .serif, weight: .bold)
    }
    /// Precios: redondeado pesado.
    static func precio(_ estilo: Font.TextStyle = .title3) -> Font {
        .system(estilo, design: .rounded, weight: .heavy)
    }
}

enum EstadoPedidoUI {
    static func color(_ e: String) -> Color {
        switch e {
        case "PENDIENTE_PAGO": AppColors.mostaza
        case "CONFIRMADO": AppColors.info
        case "EN_PREPARACION": AppColors.naranja
        case "EN_CAMINO": AppColors.morado
        case "ENTREGADO": AppColors.success
        case "CANCELADO": AppColors.danger
        default: AppColors.gris
        }
    }
    /// Variante con buen contraste para TEXTO sobre fondo suave.
    static func colorTexto(_ e: String) -> Color {
        e == "PENDIENTE_PAGO" ? AppColors.mostazaTexto : color(e)
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
