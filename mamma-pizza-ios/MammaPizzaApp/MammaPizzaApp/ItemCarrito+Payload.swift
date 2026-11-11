import Foundation

extension ItemCarrito {
    /// Cuerpo que espera POST /pedidos para cada ítem.
    var payload: [String: Any] {
        var d: [String: Any] = ["productoVarianteId": variante.id, "cantidad": cantidad]
        if !notas.isEmpty { d["notas"] = notas }
        if !agregados.isEmpty { d["agregados"] = agregados.map { ["agregadoId": $0.id] } }
        return d
    }
}
