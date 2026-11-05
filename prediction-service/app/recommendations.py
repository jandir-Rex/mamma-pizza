"""Recomendaciones locales basadas en reglas (funcionan sin IA)."""
from .schemas import IngredienteNecesidad, PronosticoProducto, Recomendacion

UMBRAL_VARIACION = 20.0  # % frente al periodo anterior


def generar_recomendaciones(
    productos: list[PronosticoProducto], ingredientes: list[IngredienteNecesidad]
) -> list[Recomendacion]:
    recs: list[Recomendacion] = []
    con_prono = [p for p in productos if p.pronostico_final is not None and p.pronostico_final > 0]

    if con_prono:
        top = sorted(con_prono, key=lambda p: p.pronostico_final, reverse=True)[:3]
        recs.append(Recomendacion(
            tipo="demanda_alta", severidad="info",
            mensaje="Mayor demanda prevista: " + ", ".join(f"{p.nombre} ({p.pronostico_final:g} u.)" for p in top) + ".",
            fundamento="Pronostico estadistico del periodo, ordenado por unidades.",
        ))

    for p in con_prono:
        if p.variacion_pct is None or p.confianza == "insuficiente":
            continue
        if p.variacion_pct >= UMBRAL_VARIACION:
            recs.append(Recomendacion(
                tipo="crecimiento", severidad="atencion",
                mensaje=f"La demanda estimada de {p.nombre} sube {p.variacion_pct:g}% frente al periodo anterior.",
                fundamento=f"Pronostico {p.pronostico_final:g} u. vs {p.ventas_periodo_anterior:g} u. vendidas en el periodo anterior (confianza {p.confianza}).",
            ))
        elif p.variacion_pct <= -UMBRAL_VARIACION:
            recs.append(Recomendacion(
                tipo="caida", severidad="atencion",
                mensaje=f"La demanda estimada de {p.nombre} baja {abs(p.variacion_pct):g}% frente al periodo anterior.",
                fundamento=f"Pronostico {p.pronostico_final:g} u. vs {p.ventas_periodo_anterior:g} u. vendidas en el periodo anterior (confianza {p.confianza}).",
            ))

    sin_datos = [p.nombre for p in productos if p.confianza == "insuficiente"]
    if sin_datos:
        recs.append(Recomendacion(
            tipo="datos_insuficientes", severidad="atencion",
            mensaje="Sin pronostico por falta de historial: " + ", ".join(sin_datos) + ".",
            fundamento="Se requieren al menos 14 dias de ventas por producto.",
        ))

    for i in ingredientes:
        if i.alerta_faltante:
            recs.append(Recomendacion(
                tipo="faltante", severidad="critica",
                mensaje=f"El inventario de {i.nombre} no cubre la necesidad proyectada: comprar {i.compra_sugerida:g} {i.unidad}.",
                fundamento=f"Necesidad ajustada {i.necesidad_ajustada:g} {i.unidad} vs disponible {i.inventario_disponible:g} + pendiente {i.compras_pendientes:g}.",
            ))
    return recs
