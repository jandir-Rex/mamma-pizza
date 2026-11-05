"""Metricas de error. Se calculan sobre totales por ventana de backtesting."""
import numpy as np


def mae(pred: list[float], real: list[float]) -> float:
    p, r = np.asarray(pred, float), np.asarray(real, float)
    return float(np.mean(np.abs(p - r)))


def wape(pred: list[float], real: list[float]) -> float | None:
    """Error absoluto ponderado: sum|e| / sum(real). None si no hubo ventas reales."""
    p, r = np.asarray(pred, float), np.asarray(real, float)
    total = float(np.sum(np.abs(r)))
    if total == 0:
        return None
    return float(np.sum(np.abs(p - r)) / total)


def smape(pred: list[float], real: list[float]) -> float | None:
    """sMAPE en porcentaje (0-200). Pares 0/0 se consideran error 0."""
    p, r = np.asarray(pred, float), np.asarray(real, float)
    den = np.abs(p) + np.abs(r)
    if len(den) == 0:
        return None
    err = np.where(den == 0, 0.0, 200.0 * np.abs(p - r) / np.where(den == 0, 1, den))
    return float(np.mean(err))
