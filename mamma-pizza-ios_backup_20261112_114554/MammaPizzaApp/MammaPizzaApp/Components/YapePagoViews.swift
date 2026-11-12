import SwiftUI
import PhotosUI

// MARK: - Utilidades

/// Captura ya reducida (máx. 1280 px, JPEG 75 %), igual que en Flutter.
struct CapturaYape {
    let datos: Data
    let imagen: UIImage

    static func cargar(_ item: PhotosPickerItem) async -> CapturaYape? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let original = UIImage(data: data) else { return nil }
        let lado = max(original.size.width, original.size.height)
        let escala = min(1, 1280 / max(lado, 1))
        let tam = CGSize(width: original.size.width * escala, height: original.size.height * escala)
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let reducida = UIGraphicsImageRenderer(size: tam, format: formato).image { _ in
            original.draw(in: CGRect(origin: .zero, size: tam))
        }
        guard let jpeg = reducida.jpegData(compressionQuality: 0.75) else { return nil }
        return CapturaYape(datos: jpeg, imagen: reducida)
    }
}

func parsearMonto(_ texto: String) -> Double? {
    Double(texto.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}

// MARK: - Formulario Yape (checkout y seguimiento)

struct YapeFormularioView: View {
    let total: Double
    @Binding var captura: CapturaYape?
    @Binding var nombre: String

    @State private var config: ConfigPago?
    @State private var cargando = true
    @State private var item: PhotosPickerItem?
    @State private var copiado = false
    @State private var errorImagen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            paso("1. Yapea \(total.soles) a este número")
            numeroYape

            paso("2. Adjunta la captura de tu Yape")
            capturaView
            if errorImagen {
                Text("No se pudo leer esa imagen. Prueba con otra.")
                    .font(.footnote).foregroundStyle(AppColors.danger)
            }

            paso("3. ¿A nombre de quién salió el Yape?")
            TextField("Nombre como aparece en la captura", text: $nombre)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
        }
        .task {
            config = try? await PedidosService.configPago()
            cargando = false
        }
        .onChange(of: item) { _, nuevo in
            guard let nuevo else { return }
            Task {
                if let c = await CapturaYape.cargar(nuevo) {
                    captura = c
                    errorImagen = false
                } else {
                    errorImagen = true
                }
                item = nil
            }
        }
    }

    private func paso(_ t: String) -> some View {
        Text(t).font(.subheadline.weight(.bold))
    }

    @ViewBuilder private var numeroYape: some View {
        if cargando {
            ProgressView().frame(maxWidth: .infinity)
        } else if let numero = config?.yapeNumero, !numero.isEmpty {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(numero)
                        .font(.title.weight(.heavy)).monospacedDigit()
                        .textSelection(.enabled)
                    if let titular = config?.yapeTitular, !titular.isEmpty {
                        Text(titular).font(.footnote).foregroundStyle(AppColors.gris)
                    }
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = numero
                    copiado = true
                    Task { try? await Task.sleep(for: .seconds(2)); copiado = false }
                } label: {
                    Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(copiado ? "Número copiado" : "Copiar número")
            }
        } else {
            Text("El número de Yape no está disponible. Comunícate con el local.")
                .font(.footnote).foregroundStyle(AppColors.danger)
        }
    }

    @ViewBuilder private var capturaView: some View {
        if let captura {
            VStack(spacing: 4) {
                Image(uiImage: captura.imagen)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Captura de tu Yape adjunta")
                HStack {
                    Spacer()
                    PhotosPicker("Cambiar", selection: $item, matching: .images)
                        .buttonStyle(.borderless)
                    Button("Quitar", role: .destructive) { self.captura = nil }
                        .buttonStyle(.borderless)
                }
            }
        } else {
            PhotosPicker(selection: $item, matching: .images) {
                Label("Adjuntar captura", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(AppColors.primary)
        }
    }
}

// MARK: - Efectivo: ¿con cuánto pagas?

struct PagaConSelector: View {
    let total: Double
    @Binding var exacto: Bool
    @Binding var texto: String

    private var sugeridos: [Int] { [50, 100, 200].filter { Double($0) >= total } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("¿Con cuánto pagarás?").font(.subheadline.weight(.bold))
                Text("Así el repartidor te lleva el vuelto exacto.")
                    .font(.footnote).foregroundStyle(AppColors.gris)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("Monto exacto", activo: exacto) {
                        texto = ""
                        exacto = true
                    }
                    ForEach(sugeridos, id: \.self) { m in
                        chip("S/ \(m)", activo: !exacto && texto == "\(m)") {
                            texto = "\(m)"
                            exacto = false
                        }
                    }
                }
            }

            TextField("Otro monto", text: $texto, prompt: Text("Otro monto"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: texto) { _, nuevo in
                    if !nuevo.isEmpty { exacto = false }
                }

            if !exacto, let monto = parsearMonto(texto) {
                if monto < total {
                    Text("El monto debe ser al menos \(total.soles)")
                        .font(.footnote).foregroundStyle(AppColors.danger)
                } else {
                    Text("Vuelto a recibir: \((monto - total).soles)")
                        .font(.footnote.weight(.bold))
                }
            }
        }
    }

    private func chip(_ titulo: String, activo: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Text(titulo)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .foregroundStyle(activo ? Color.white : AppColors.texto)
                .background(Capsule().fill(activo ? AppColors.primary : AppColors.surface))
                .overlay(Capsule().stroke(activo ? AppColors.primary : AppColors.hairline))
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(activo ? .isSelected : [])
    }
}

// MARK: - Seguimiento: estado de la revisión del Yape

struct ComprobanteYapeCard: View {
    let pedido: Pedido
    var onEnviado: () async -> Void

    @State private var captura: CapturaYape?
    @State private var nombre = ""
    @State private var enviando = false
    @State private var error: String?

    var body: some View {
        if pedido.comprobanteEstado == "EN_REVISION" {
            Label {
                Text("Estamos revisando tu Yape. Te avisaremos apenas lo confirmemos.")
                    .font(.footnote.weight(.semibold))
            } icon: {
                Image(systemName: "hourglass").foregroundStyle(AppColors.warning)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            formulario
        }
    }

    private var formulario: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pedido.comprobanteEstado == "RECHAZADO" {
                Text("No pudimos validar tu Yape: \(pedido.comprobanteMotivo ?? "revisa los datos"). Sube una nueva captura.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.danger)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text("Falta la captura de tu Yape").font(.subheadline.weight(.heavy))
            }

            YapeFormularioView(total: pedido.total, captura: $captura, nombre: $nombre)

            if let error {
                Text(error).font(.footnote).foregroundStyle(AppColors.danger)
            }

            Button { Task { await enviar() } } label: {
                HStack {
                    if enviando { ProgressView() }
                    Text("Enviar comprobante").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(enviando)
        }
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func enviar() async {
        guard let captura else { error = "Adjunta la captura de tu Yape"; return }
        let quien = nombre.trimmingCharacters(in: .whitespaces)
        guard quien.count >= 2 else { error = "Indica el nombre de quien yapeó"; return }
        enviando = true
        error = nil
        defer { enviando = false }
        do {
            try await PedidosService.subirComprobante(pedido.id, captura: captura.datos, yapeNombre: quien)
            self.captura = nil
            await onEnviado()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Disculpa por demora

struct AvisoDemora: View {
    let enRevision: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🙏").font(.title2)
            Text(enRevision
                 ? "Disculpa la demora. Estamos revisando tu pago y en breve confirmaremos tu pedido."
                 : "Disculpa la demora, estamos con mucha atención en el local. Tu pedido ya está registrado y lo confirmaremos en unos minutos.")
                .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
