"""Modelos de pronostico diario. Cada modelo devuelve unidades esperadas por cada dia objetivo.

Orden de simplicidad (se usa para desempatar): ultimo_periodo < promedio_movil < perfil_semanal < ets_holt_winters.
"""
import warnings
from datetime import date

import numpy as np


class ModeloNoDisponible(Exception):
    """El modelo no puede ejecutarse con estos datos (poca historia, serie degenerada...)."""


def ultimo_periodo(hist: np.ndarray, fechas: list[date], objetivo: list[date]) -> np.ndarray:
    """Baseline: promedio diario de los ultimos H dias (H = largo del periodo objetivo)."""
    h = len(objetivo)
    ventana = hist[-h:] if len(hist) >= 1 else hist
    return np.full(h, float(ventana.mean()) if len(ventana) else 0.0)


def promedio_movil(hist: np.ndarray, fechas: list[date], objetivo: list[date]) -> np.ndarray:
    """Promedio diario de los ultimos 28 dias."""
    ventana = hist[-28:]
    return np.full(len(objetivo), float(ventana.mean()) if len(ventana) else 0.0)


def perfil_semanal(hist: np.ndarray, fechas: list[date], objetivo: list[date]) -> np.ndarray:
    """Promedio por dia de la semana sobre las ultimas 8 semanas (captura el patron semanal)."""
    n = min(56, len(hist))
    reciente, f_rec = hist[-n:], fechas[-n:]
    general = float(reciente.mean()) if n else 0.0
    por_dia: dict[int, float] = {}
    for w in range(7):
        vals = [v for v, f in zip(reciente, f_rec) if f.weekday() == w]
        if vals:
            por_dia[w] = float(np.mean(vals))
    return np.array([por_dia.get(d.weekday(), general) for d in objetivo], dtype=float)


def ets_holt_winters(hist: np.ndarray, fechas: list[date], objetivo: list[date]) -> np.ndarray:
    """Suavizamiento exponencial con tendencia amortiguada y estacionalidad semanal aditiva."""
    if len(hist) < 28:
        raise ModeloNoDisponible("ETS requiere al menos 28 dias de historial")
    if float(np.sum(hist)) <= 0:
        raise ModeloNoDisponible("Serie sin ventas")
    try:
        from statsmodels.tsa.holtwinters import ExponentialSmoothing

        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            ajuste = ExponentialSmoothing(
                hist.astype(float),
                trend="add",
                damped_trend=True,
                seasonal="add",
                seasonal_periods=7,
                initialization_method="estimated",
            ).fit()
            pasos = (objetivo[-1] - fechas[-1]).days
            if pasos < 1:
                raise ModeloNoDisponible("El periodo objetivo debe ser posterior a los datos")
            prono = np.asarray(ajuste.forecast(pasos), dtype=float)
    except ModeloNoDisponible:
        raise
    except Exception as exc:  # statsmodels puede fallar por convergencia o datos degenerados
        raise ModeloNoDisponible(f"ETS fallo: {exc}") from exc
    idx = [(d - fechas[-1]).days - 1 for d in objetivo]
    salida = np.clip(prono[idx], 0, None)
    if not np.all(np.isfinite(salida)):
        raise ModeloNoDisponible("ETS produjo valores no finitos")
    return salida


MODELOS = {
    "ultimo_periodo": ultimo_periodo,
    "promedio_movil": promedio_movil,
    "perfil_semanal": perfil_semanal,
    "ets_holt_winters": ets_holt_winters,
}
ORDEN_SIMPLICIDAD = ["ultimo_periodo", "promedio_movil", "perfil_semanal", "ets_holt_winters"]
