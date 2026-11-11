"""Orquesta el flujo completo: datos -> motor estadistico -> IA (opcional) -> evaluacion -> abastecimiento -> reglas."""
from .ai.manager import analizar_con_ia
from .config import Settings
from .data import construir_series
from .historial import construir_serie_historica
from .forecasting.predictor import dias_objetivo, pronosticar_producto
from .recommendations import generar_recomendaciones
from .schemas import AnalisisRequest, AnalisisResponse, EstadoMotor, Recomendacion
from .supply import calcular_abastecimiento

VERSION = "1.0.0"
UMBRAL_DISCREPANCIA = 0.25  # |IA - estadistico| / estadistico


def analizar(req: AnalisisRequest, settings: Settings) -> AnalisisResponse:
    advertencias: list[str] = []
    datos = construir_series(req.ventas, req.fecha_corte)
    advertencias += datos.advertencias
    objetivo = dias_objetivo(req.periodo.inicio, req.periodo.fin)

    # Motor A: estadistico (autonomo)
    productos = [pronosticar_producto(s, objetivo) for s in sorted(datos.series.values(), key=lambda x: x.nombre.lower())]
    motor_a = EstadoMotor(estado="completado", detalle=f"{len(productos)} productos evaluados")

    # Motor B: IA cloud (opcional, nunca bloquea)
    motor_b, analisis_ia, ia_num = analizar_con_ia(
        settings, req.config.ia_habilitada, datos, productos, req.periodo.inicio, req.periodo.fin
    )
    recs: list[Recomendacion] = []
    discrepancias = 0
    for p in productos:
        if p.producto_id in ia_num:
            p.pronostico_ia = ia_num[p.producto_id]
            base = p.pronostico_estadistico
            if base and base > 0 and abs(p.pronostico_ia - base) / base > UMBRAL_DISCREPANCIA:
                discrepancias += 1
                recs.append(Recomendacion(
                    tipo="discrepancia_motores", severidad="atencion", origen="reglas",
                    mensaje=f"Los motores discrepan en {p.nombre}: estadistico {base:g} u. vs IA {p.pronostico_ia:g} u.",
                    fundamento="Diferencia mayor al 25%. Se usa el estadistico; la cifra de la IA se guarda para evaluarla contra las ventas reales.",
                ))

    # Motor C: evaluacion/combinacion. Sin historial de pronosticos de IA evaluados contra ventas reales NO se combina.
    evaluacion = {
        "modo": "solo_estadistico",
        "combinacion_habilitada": False,
        "motivo": "La IA aun no tiene pronosticos evaluados contra ventas reales; no se promedian los motores sin evidencia de desempeno.",
        "productos_con_pronostico_ia": len(ia_num),
        "discrepancias": discrepancias,
    }

    # Abastecimiento determinista, solo con el pronostico final
    finales = {p.producto_id: p.pronostico_final for p in productos if p.pronostico_final is not None}
    nombres = {p.producto_id: p.nombre for p in productos}
    ingredientes, adv_sup = calcular_abastecimiento(finales, nombres, req.recetas, req.inventario)
    advertencias += adv_sup

    comparable = datos.meta.get("dias_historial", 0) >= 2 * len(objetivo)
    recs = generar_recomendaciones(productos, ingredientes, comparable) + recs
    if analisis_ia:
        for texto in analisis_ia.recomendaciones[:5]:
            recs.append(Recomendacion(tipo="analisis_ia", severidad="info", mensaje=texto,
                                      fundamento="Analisis automatizado por IA con datos agregados; verificar antes de actuar.", origen="ia"))
    if motor_b.estado in ("no_disponible", "error"):
        advertencias.append(f"Analisis de IA no disponible: {motor_b.detalle}. El pronostico estadistico no se ve afectado.")

    estado = "completado" if motor_b.estado in ("completado", "deshabilitado") else "parcial"
    return AnalisisResponse(
        version_servicio=VERSION,
        periodo=req.periodo,
        fecha_corte=req.fecha_corte,
        estado=estado,
        motores={"estadistico": motor_a, "ia_cloud": motor_b,
                 "evaluacion": EstadoMotor(estado="completado", detalle=evaluacion["modo"])},
        datos={**datos.meta, "variacion_comparable": comparable, "dias_periodo": len(objetivo), "registros_ventas_recibidos": len(req.ventas), "recetas_recibidas": len(req.recetas),
               "ingredientes_en_inventario": len(req.inventario)},
        productos=productos,
        ingredientes=ingredientes,
        evaluacion=evaluacion,
        analisis_ia=analisis_ia,
        serie_historica=construir_serie_historica(datos, req.fecha_corte),
        recomendaciones=recs,
        advertencias=advertencias,
    )
