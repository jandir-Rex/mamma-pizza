"""Seleccion de modelo por producto mediante backtesting (sin usar informacion futura)."""
from datetime import date, timedelta

import numpy as np

from ..data import Serie
from ..schemas import MetricasModelo, PronosticoProducto
from . import metrics
from .models import MODELOS, ORDEN_SIMPLICIDAD, ModeloNoDisponible

MIN_DIAS_PRONOSTICO = 14   # menos que esto: no se pronostica
MIN_DIAS_ENTRENAMIENTO = 28  # historia minima para entrenar en cada ventana del backtest
MAX_VENTANAS = 4
PASO_VENTANAS = 7
MEJORA_MINIMA = 0.05       # un modelo mas complejo debe mejorar al menos 5% el WAPE para ser elegido
# Multiplicador t (80% bilateral) segun ventanas de backtesting: con pocas ventanas el intervalo es mas ancho
T_80 = {3: 1.886, 4: 1.638}


def dias_objetivo(inicio: date, fin: date) -> list[date]:
    return [inicio + timedelta(days=i) for i in range((fin - inicio).days + 1)]


def _ventanas(n: int, h: int) -> list[int]:
    """Indices de corte de entrenamiento (train = [:e], test = [e:e+h]). e = n - h - k*7."""
    cortes = []
    for k in range(MAX_VENTANAS):
        e = n - h - PASO_VENTANAS * k
        if e >= MIN_DIAS_ENTRENAMIENTO:
            cortes.append(e)
    return cortes


def _backtest(serie: Serie, nombre_modelo: str, h: int, cortes: list[int]) -> tuple[list[float], list[float]] | None:
    fn = MODELOS[nombre_modelo]
    preds, reales = [], []
    for e in cortes:
        train_v, train_f = serie.valores[:e], serie.fechas[:e]
        test_f = serie.fechas[e : e + h]
        test_v = serie.valores[e : e + h]
        try:
            diario = fn(train_v, train_f, test_f)
        except ModeloNoDisponible:
            return None
        preds.append(float(np.sum(diario)))
        reales.append(float(np.sum(test_v)))
    return preds, reales


def pronosticar_producto(serie: Serie, objetivo: list[date]) -> PronosticoProducto:
    n, h = len(serie), len(objetivo)
    anterior = float(np.sum(serie.valores[-h:]))
    advertencias: list[str] = []
    base = dict(
        producto_id=serie.producto_id,
        nombre=serie.nombre,
        ventas_periodo_anterior=round(anterior, 1),
    )

    if (serie.fechas[-1] - serie.primera_venta).days + 1 < 30 and n < 30:
        advertencias.append("Producto nuevo (menos de 30 dias con ventas): el pronostico es poco fiable.")

    if n < MIN_DIAS_PRONOSTICO:
        advertencias.append(f"Solo {n} dias de historial: no se genera pronostico.")
        return PronosticoProducto(
            **base, pronostico_estadistico=None, modelo=None, metricas=MetricasModelo(horizonte_dias=h),
            confianza="insuficiente", advertencias=advertencias, pronostico_final=None, metodo_final="sin_datos",
        )

    cortes = _ventanas(n, h)
    comparacion: dict[str, float | None] = {}
    elegido: str
    met = MetricasModelo(horizonte_dias=h)
    intervalo = (None, None, None)

    if not cortes:
        elegido = "perfil_semanal" if n >= 28 else "promedio_movil"
        advertencias.append(
            "Historial insuficiente para evaluar modelos con backtesting; se usa un metodo simple con confianza baja."
        )
        confianza = "baja"
    else:
        resultados: dict[str, tuple[list[float], list[float]]] = {}
        for nombre in ORDEN_SIMPLICIDAD:
            r = _backtest(serie, nombre, h, cortes)
            if r is not None:
                resultados[nombre] = r
        if not resultados:
            elegido = "promedio_movil"
            confianza = "baja"
            advertencias.append("No se pudo evaluar ningun modelo; se usa promedio movil.")
        else:
            def puntaje(nombre: str) -> float:
                p, r = resultados[nombre]
                w = metrics.wape(p, r)
                return w if w is not None else metrics.mae(p, r)

            for nombre, (p, r) in resultados.items():
                comparacion[nombre] = None if metrics.wape(p, r) is None else round(metrics.wape(p, r), 4)

            elegido = ORDEN_SIMPLICIDAD[0] if ORDEN_SIMPLICIDAD[0] in resultados else next(iter(resultados))
            mejor = puntaje(elegido)
            for nombre in ORDEN_SIMPLICIDAD:
                if nombre in resultados and nombre != elegido and puntaje(nombre) < mejor * (1 - MEJORA_MINIMA):
                    elegido, mejor = nombre, puntaje(nombre)

            p, r = resultados[elegido]
            w = metrics.wape(p, r)
            met = MetricasModelo(
                mae=round(metrics.mae(p, r), 2),
                wape=None if w is None else round(w, 4),
                smape=None if metrics.smape(p, r) is None else round(metrics.smape(p, r), 2),
                ventanas=len(cortes),
                horizonte_dias=h,
            )
            if len(cortes) >= 3 and w is not None and w <= 0.25 and n >= 90:
                confianza = "alta"
            elif len(cortes) >= 2 and w is not None and w <= 0.5:
                confianza = "media"
            else:
                confianza = "baja"
            if len(cortes) >= 3:
                errores = np.array(r) - np.array(p)
                sd = float(np.std(errores, ddof=1))
                intervalo = (sd * T_80.get(len(cortes), 1.638), 0.8, None)  # (semiancho del intervalo, nivel, reservado)

    try:
        diario = MODELOS[elegido](serie.valores, serie.fechas, objetivo)
    except ModeloNoDisponible:
        elegido = "perfil_semanal"
        advertencias.append("El modelo elegido no pudo ejecutarse con el historial completo; se uso perfil semanal.")
        diario = MODELOS[elegido](serie.valores, serie.fechas, objetivo)
    total = float(np.sum(diario))
    inf = sup = nivel = None
    if intervalo[0] is not None:
        semiancho = intervalo[0]
        inf, sup, nivel = round(max(0.0, total - semiancho), 1), round(total + semiancho, 1), 0.8
    variacion = round((total - anterior) / anterior * 100, 1) if anterior > 0 else None

    return PronosticoProducto(
        **base,
        pronostico_estadistico=round(total, 1),
        limite_inferior=inf,
        limite_superior=sup,
        nivel_intervalo=nivel,
        variacion_pct=variacion,
        modelo=elegido,
        metricas=met,
        comparacion_modelos=comparacion,
        confianza=confianza,
        advertencias=advertencias,
        pronostico_final=round(total, 1),
        metodo_final="estadistico",
    )
