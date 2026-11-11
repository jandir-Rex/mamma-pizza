import SwiftUI

// MARK: - Tarjeta base

struct TarjetaModifier: ViewModifier {
    var padding: CGFloat
    var radio: CGFloat
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: radio, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radio, style: .continuous)
                .strokeBorder(AppColors.hairline, lineWidth: 0.5))
            .shadow(color: .black.opacity(esquema == .dark ? 0 : 0.05), radius: 12, y: 4)
    }
}

extension View {
    func tarjeta(padding: CGFloat = 16, radio: CGFloat = 20) -> some View {
        modifier(TarjetaModifier(padding: padding, radio: radio))
    }
    func fondoApp() -> some View { background(AppColors.bg.ignoresSafeArea()) }
}

// MARK: - Botones

struct BotonPrimario: ButtonStyle {
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .tint(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(habilitado ? Color.white : AppColors.gris)
            .background(habilitado ? AppColors.primary : AppColors.hairline,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct BotonSecundario: ButtonStyle {
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(habilitado ? AppColors.primary : AppColors.gris)
            .background(AppColors.primary.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Solo la animación de presión (para tarjetas y filas tocables).
struct PresionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BotonPrimario { static var primario: BotonPrimario { BotonPrimario() } }
extension ButtonStyle where Self == BotonSecundario { static var secundario: BotonSecundario { BotonSecundario() } }
extension ButtonStyle where Self == PresionStyle { static var presion: PresionStyle { PresionStyle() } }

// MARK: - Piezas reutilizables

struct EncabezadoSeccion: View {
    let titulo: String
    var boton: String?
    var accion: (() -> Void)?

    init(_ titulo: String, boton: String? = nil, accion: (() -> Void)? = nil) {
        self.titulo = titulo
        self.boton = boton
        self.accion = accion
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titulo).font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
            Spacer()
            if let boton, let accion {
                Button(boton, action: accion).font(.subheadline.weight(.semibold))
            }
        }
    }
}

struct BannerError: View {
    let texto: String
    init(_ texto: String) { self.texto = texto }

    var body: some View {
        Label { Text(texto).font(.footnote) } icon: { Image(systemName: "exclamationmark.circle.fill") }
            .foregroundStyle(AppColors.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

struct InsigniaEstado: View {
    let estado: String

    var body: some View {
        Label(EstadoPedidoUI.etiqueta(estado), systemImage: EstadoPedidoUI.icono(estado))
            .font(.caption.weight(.semibold))
            .foregroundStyle(EstadoPedidoUI.colorTexto(estado))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(EstadoPedidoUI.color(estado).opacity(0.14), in: Capsule())
    }
}

/// Campo de formulario con ícono (login, registro).
struct CampoFormulario<Contenido: View>: View {
    let icono: String
    @ViewBuilder var contenido: Contenido

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .foregroundStyle(AppColors.gris)
                .frame(width: 22)
                .accessibilityHidden(true)
            contenido
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(AppColors.hairline, lineWidth: 1))
    }
}

/// Fila seleccionable (dirección, método de pago).
struct FilaSeleccion: View {
    let icono: String
    let titulo: String
    var subtitulo: String? = nil
    let activo: Bool
    var habilitado: Bool = true
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(activo ? Color.white : AppColors.cacaoTexto)
                    .frame(width: 40, height: 40)
                    .background(activo ? AppColors.primary : AppColors.kraftClaro, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo).font(.body.weight(.semibold)).foregroundStyle(AppColors.texto)
                    if let subtitulo, !subtitulo.isEmpty {
                        Text(subtitulo).font(.footnote).foregroundStyle(AppColors.gris).lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: activo ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(activo ? AppColors.primary : AppColors.grisClaro)
            }
            .padding(12)
            .frame(minHeight: 56)
            .background(activo ? AppColors.kraftClaro.opacity(0.6) : AppColors.surface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(activo ? AppColors.primary : AppColors.hairline, lineWidth: activo ? 1.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.presion)
        .disabled(!habilitado)
        .opacity(habilitado ? 1 : 0.5)
        .sensoryFeedback(.selection, trigger: activo)
        .accessibilityAddTraits(activo ? .isSelected : [])
    }
}

/// Fondo cálido con círculos suaves (login, registro).
struct FondoMarca: View {
    var body: some View {
        ZStack(alignment: .top) {
            AppColors.bg
            Circle().fill(AppColors.kraft.opacity(0.45)).frame(width: 340).offset(x: 130, y: -190)
            Circle().fill(AppColors.primary.opacity(0.08)).frame(width: 220).offset(x: -150, y: -80)
        }
        .ignoresSafeArea()
    }
}
