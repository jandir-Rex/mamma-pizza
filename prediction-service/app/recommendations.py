"""Recomendaciones locales basadas en reglas (funcionan sin IA)."""
def _n(x: float) -> str:
    """Numero legible: sin decimales si es grande, 1 decimal si es pequeno."""
    texto = f"{x:,.0f}" if abs(x) >= 100 else f"{x:,.1f}"
    return texto[:-2] if texto.endswith(".0") else texto


from .schemas import IngredienteNecesidad, PronosticoProducto, Recomendacion

UMBRAL_VARIACION = 20.0  # % frente al periodo anterior


def generar_recomendaciones(
    productos: list[PronosticoProducto], ingredientes: list[IngredienteNecesidad], comparable: bool = True
) -> list[Recomendacion]:
    """comparable=False cuando el historial es mas corto que el doble del periodo: no se comparan variaciones."""
    recs: list[Recomendacion] = []
    con_prono = [p for p in productos if p.pronostico_final is not None and p.pronostico_final > 0]

    if con_prono:
        top = sorted(con_prono, key=lambda p: p.pronostico_final, reverse=True)[:3]
        recs.append(Recomendacion(
            tipo="demanda_alta", severidad="info",
            mensaje="Mayor demanda prevista: " + ", ".join(f"{p.nombre} ({_n(p.pronostico_final)} u.)" for p in top) + ".",
            fundamento="Pronostico estadistico del periodo, ordenado por unidades.",
        ))

    for p in con_prono:
        if not comparable or p.variacion_pct is None or p.confianza == "insuficiente":
            continue
        if p.variacion_pct >= UMBRAL_VARIACION:
            recs.append(Recomendacion(
                tipo="crecimiento", severidad="atencion",
                mensaje=f"La demanda estimada de {p.nombre} sube {_n(p.variacion_pct)}% frente al periodo anterior.",
                fundamento=f"Pronostico {_n(p.pronostico_final)} u. vs {_n(p.ventas_periodo_anterior)} u. vendidas en el periodo anterior (confianza {p.confianza}).",
            ))
        elif p.variacion_pct <= -UMBRAL_VARIACION:
            recs.append(Recomendacion(
                tipo="caida", severidad="atencion",
                mensaje=f"La demanda estimada de {p.nombre} baja {_n(abs(p.variacion_pct))}% frente al periodo anterior.",
                fundamento=f"Pronostico {_n(p.pronostico_final)} u. vs {_n(p.ventas_periodo_anterior)} u. vendidas en el periodo anterior (confianza {p.confianza}).",
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
                mensaje=f"El inventario de {i.nombre} no cubre la necesidad proyectada: comprar {_n(i.compra_sugerida)} {i.unidad}.",
                fundamento=f"Necesidad ajustada {_n(i.necesidad_ajustada)} {i.unidad} vs disponible {_n(i.inventario_disponible)} + pendiente {_n(i.compras_pendientes)}.",
            ))
    return recs
