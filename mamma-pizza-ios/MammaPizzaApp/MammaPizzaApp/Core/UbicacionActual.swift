import CoreLocation

@MainActor
final class UbicacionActual: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuacion: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func obtener() async throws -> CLLocationCoordinate2D {
        let estado = manager.authorizationStatus
        if estado == .denied || estado == .restricted { throw Self.errorPermiso }

        return try await withCheckedThrowingContinuation { c in
            continuacion?.resume(throwing: CancellationError())
            continuacion = c
            if estado == .notDetermined { manager.requestWhenInUseAuthorization() }
            else { manager.requestLocation() }
        }
    }

    private static let errorPermiso =
        APIError.mensaje("Sin permiso de ubicación. Puedes buscar tu calle o mover el mapa.")

    private func terminar(_ resultado: Result<CLLocationCoordinate2D, Error>) {
        continuacion?.resume(with: resultado)
        continuacion = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let estado = manager.authorizationStatus
        Task { @MainActor in
            guard self.continuacion != nil else { return }
            switch estado {
            case .authorizedWhenInUse, .authorizedAlways: self.manager.requestLocation()
            case .denied, .restricted: self.terminar(.failure(Self.errorPermiso))
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        Task { @MainActor in self.terminar(.success(c)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.terminar(.failure(APIError.mensaje("No se pudo obtener tu ubicación. Revisa que el GPS esté activo.")))
        }
    }
}
