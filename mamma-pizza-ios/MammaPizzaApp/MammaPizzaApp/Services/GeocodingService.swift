import Foundation
import CoreLocation

struct LugarEncontrado: Identifiable {
    let id = UUID()
    let titulo: String
    let detalle: String
    let coordenada: CLLocationCoordinate2D
}

enum GeocodingService {
    private static let cercaDeTrujillo = "-79.0287,-8.1116" // lng,lat

    private static func url(_ path: String, _ items: [String: String]) -> URL? {
        var c = URLComponents()
        c.scheme = "https"; c.host = "api.mapbox.com"; c.path = path
        c.queryItems = items.map { URLQueryItem(name: $0.key, value: $0.value) }
            + [URLQueryItem(name: "access_token", value: AppConfig.mapboxToken)]
        return c.url
    }

    private static func fetch(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.mensaje("No se pudo buscar la dirección")
        }
        return data
    }

    /// Busca direcciones en Perú, priorizando Trujillo.
    static func buscar(_ consulta: String) async throws -> [LugarEncontrado] {
        guard AppConfig.mapboxConfigurado else { throw APIError.mensaje("Falta el token de Mapbox (MAPBOX_TOKEN)") }
        guard let u = url("/search/geocode/v6/forward", [
            "q": consulta, "country": "pe", "language": "es",
            "limit": "6", "proximity": cercaDeTrujillo
        ]) else { return [] }
        return lugares(de: try await fetch(u))
    }

    /// Coordenadas -> dirección legible. Devuelve nil si falla.
    static func direccionDe(_ punto: CLLocationCoordinate2D) async -> String? {
        guard AppConfig.mapboxConfigurado,
              let u = url("/search/geocode/v6/reverse", [
                "longitude": String(punto.longitude), "latitude": String(punto.latitude),
                "language": "es", "types": "address,street,neighborhood,locality", "limit": "1"
              ]),
              let data = try? await fetch(u) else { return nil }
        return lugares(de: data).first?.titulo
    }

    private static func lugares(de data: Data) -> [LugarEncontrado] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else { return [] }
        return features.compactMap(aLugar)
    }

    /// Mapbox entrega coordenadas como [lng, lat]: ojo con el orden.
    private static func aLugar(_ f: [String: Any]) -> LugarEncontrado? {
        let props = f["properties"] as? [String: Any] ?? [:]
        func s(_ k: String) -> String { (props[k] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }

        var lat: Double?, lng: Double?
        if let c = props["coordinates"] as? [String: Any] {
            lat = (c["latitude"] as? NSNumber)?.doubleValue
            lng = (c["longitude"] as? NSNumber)?.doubleValue
        }
        if lat == nil || lng == nil,
           let g = (f["geometry"] as? [String: Any])?["coordinates"] as? [Double], g.count >= 2 {
            lng = g[0]; lat = g[1]
        }
        guard let lat, let lng else { return nil }

        let nombre = s("name_preferred").isEmpty ? s("name") : s("name_preferred")
        let contexto = s("place_formatted")
        let completo = s("full_address")
        let titulo = nombre.isEmpty ? completo : (contexto.isEmpty ? nombre : "\(nombre), \(contexto)")
        guard !titulo.isEmpty else { return nil }

        return LugarEncontrado(titulo: titulo,
                               detalle: completo.isEmpty ? titulo : completo,
                               coordenada: CLLocationCoordinate2D(latitude: lat, longitude: lng))
    }
}
