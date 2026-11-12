
import SwiftUI
import MapKit

private let centroTrujillo = CLLocationCoordinate2D(
    latitude: -8.1116,
    longitude: -79.0287
)

/// Elige la ubicación exacta de entrega. Al confirmar guarda la dirección en el backend
/// y la devuelve por `onGuardada`.
struct SeleccionarUbicacionView: View {
    var onGuardada: (Direccion) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var posicion: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: centroTrujillo,
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )
    )

    @State private var centro = centroTrujillo
    @State private var busqueda = ""
    @State private var direccion = ""
    @State private var referencia = ""
    @State private var resultados: [LugarEncontrado] = []

    @State private var ubicacionElegida = false
    @State private var buscando = false
    @State private var ubicando = false
    @State private var resolviendo = false
    @State private var guardando = false
    @State private var error: String?

    @State private var gps = UbicacionActual()
    @State private var debounce: Task<Void, Never>?
    @State private var reqId = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !AppConfig.mapboxConfigurado {
                    Text("Falta un token público de Mapbox (pk.) en AppConfig.swift.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.danger.opacity(0.1))
                }

                mapa
            }
            .navigationTitle("Ubicación de entrega")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .searchable(
                text: $busqueda,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Busca tu calle o avenida"
            )
            .onSubmit(of: .search) {
                Task { await buscar() }
            }
            .safeAreaInset(edge: .bottom) {
                panelInferior
            }
            .task {
                await usarMiUbicacion(silencioso: true)
            }
        }
    }

    // MARK: UI

    private var mapa: some View {
        Map(position: $posicion, interactionModes: [.pan, .zoom]) {
            UserAnnotation()
        }
        .onMapCameraChange(frequency: .onEnd) { ctx in
            alMoverMapa(ctx.region.center)
        }
        .overlay {
            // Pin fijo al centro: la punta queda justo sobre el punto elegido
            Image(systemName: "mappin")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .padding(.bottom, 36)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .top) {
            if !resultados.isEmpty {
                List(resultados) { l in
                    Button {
                        elegir(l)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.titulo)
                                .lineLimit(1)
                                .foregroundStyle(AppColors.texto)

                            Text(l.detalle)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(AppColors.gris)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 240)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
                .shadow(radius: 6)
                .padding(12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                Task { await usarMiUbicacion() }
            } label: {
                Group {
                    if ubicando {
                        ProgressView()
                    } else {
                        Image(systemName: "location.fill")
                    }
                }
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
            }
            .disabled(ubicando)
            .padding(12)
            .accessibilityLabel("Usar mi ubicación")
        }
        .overlay(alignment: .topTrailing) {
            if buscando {
                ProgressView()
                    .padding(12)
            }
        }
    }

    // MARK: Panel inferior

    private var panelInferior: some View {
        VStack(spacing: 12) {
            CampoFormulario(icono: "mappin.and.ellipse") {
                TextField("Dirección", text: $direccion, axis: .vertical)
                    .lineLimit(1...2)
                    .textContentType(.fullStreetAddress)
                    .padding(.vertical, 10)

                if resolviendo {
                    ProgressView()
                }
            }

            CampoFormulario(icono: "text.bubble") {
                TextField(
                    "Referencia (opcional): casa verde, portón negro…",
                    text: $referencia
                )
            }

            if let error {
                BannerError(error)
            }

            Button {
                Task { await confirmar() }
            } label: {
                HStack(spacing: 8) {
                    if guardando {
                        ProgressView()
                    }

                    Text("Confirmar ubicación")
                }
            }
            .buttonStyle(.primario)
            // Deshabilitar hasta que sea válido: ubicación elegida + dirección escrita.
            // Se evita que el usuario toque el botón y reciba un error después.
            .disabled(guardando || !ubicacionElegida || direccion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24,
                style: .continuous
            )
            .fill(.regularMaterial)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: Mapa

    private func alMoverMapa(_ nuevo: CLLocationCoordinate2D) {
        let metros = CLLocation(
            latitude: nuevo.latitude,
            longitude: nuevo.longitude
        )
        .distance(
            from: CLLocation(
                latitude: centro.latitude,
                longitude: centro.longitude
            )
        )

        guard metros > 3 else { return }

        centro = nuevo
        ubicacionElegida = true

        debounce?.cancel()

        debounce = Task {
            try? await Task.sleep(for: .milliseconds(700))

            if !Task.isCancelled {
                await resolverDireccion()
            }
        }
    }

    private func mover(a punto: CLLocationCoordinate2D) {
        centro = punto

        withAnimation {
            posicion = .region(
                MKCoordinateRegion(
                    center: punto,
                    latitudinalMeters: 400,
                    longitudinalMeters: 400
                )
            )
        }
    }

    private func resolverDireccion() async {
        reqId += 1
        let id = reqId

        resolviendo = true

        let texto = await GeocodingService.direccionDe(centro)

        guard id == reqId else { return }

        resolviendo = false

        if let texto {
            direccion = texto
        }
    }

    // MARK: GPS

    private func usarMiUbicacion(silencioso: Bool = false) async {
        guard !ubicando else { return }

        ubicando = true

        if !silencioso {
            error = nil
        }

        defer {
            ubicando = false
        }

        do {
            let punto = try await gps.obtener()

            mover(a: punto)
            ubicacionElegida = true

            await resolverDireccion()
        } catch {
            if !silencioso {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: Búsqueda

    private func buscar() async {
        let consulta = busqueda.trimmingCharacters(
            in: .whitespaces
        )

        guard consulta.count >= 3 else { return }

        buscando = true
        error = nil

        defer {
            buscando = false
        }

        do {
            resultados = try await GeocodingService.buscar(consulta)

            if resultados.isEmpty {
                error = "No encontramos esa dirección. Prueba con otra o mueve el mapa."
            }
        } catch {
            let msg = error.localizedDescription

            self.error = msg.hasPrefix("Falta")
                ? msg
                : "No se pudo buscar. Revisa tu conexión."
        }
    }

    private func elegir(_ lugar: LugarEncontrado) {
        mover(a: lugar.coordenada)

        ubicacionElegida = true
        resultados = []
        busqueda = lugar.titulo
        direccion = lugar.titulo
    }

    // MARK: Guardar

    private func confirmar() async {
        let texto = direccion.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard ubicacionElegida else {
            error = "Usa tu ubicación, busca tu calle o mueve el mapa hasta tu puerta."
            return
        }

        guard !texto.isEmpty else {
            error = "Escribe la dirección de entrega"
            return
        }

        guardando = true
        error = nil

        defer {
            guardando = false
        }

        do {
            let nueva = try await DireccionesService.crear(
                zona: texto,
                referencia: referencia.trimmingCharacters(
                    in: .whitespaces
                ),
                lat: centro.latitude,
                lng: centro.longitude
            )

            onGuardada(nueva)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

