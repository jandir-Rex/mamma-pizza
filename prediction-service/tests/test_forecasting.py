from datetime import date, timedelta

import numpy as np
import pytest

from app.data import construir_series
from app.forecasting import metrics
from app.forecasting.predictor import dias_objetivo, pronosticar_producto
from app.schemas import VentaDia
from tests.conftest import ventas_sinteticas

FIN = date(2026, 11, 2)
OBJ = dias_objetivo(date(2026, 12, 1), date(2026, 12, 31))


def _series(dias, **kw):
    filas = ventas_sinteticas(dias, FIN, **kw)
    return construir_series([VentaDia(**f) for f in filas], FIN)


def test_metricas():
    assert metrics.mae([10, 20], [12, 18]) == 2
    assert metrics.wape([10, 20], [12, 18]) == pytest.approx(4 / 30)
    assert metrics.wape([1], [0]) is None
    assert metrics.smape([0], [0]) == 0


def test_historial_largo_da_pronostico_razonable_y_evaluado():
    datos = _series(300)
    s = datos.series[1]
    r = pronosticar_producto(s, OBJ)
    # Verdad aproximada: suma del patron semanal sobre diciembre
    semanal = [0.7, 0.7, 0.8, 0.9, 1.2, 1.6, 1.5]
    real = sum(20 * semanal[d.weekday()] for d in OBJ)
    assert r.pronostico_final == pytest.approx(real, rel=0.12)
    assert r.metricas.ventanas >= 3
    assert r.metricas.wape is not None and r.metricas.wape < 0.2
    assert r.confianza == "alta"
    assert r.limite_inferior is not None and r.limite_inferior <= r.pronostico_final <= r.limite_superior
    assert r.modelo in {"perfil_semanal", "ets_holt_winters", "promedio_movil", "ultimo_periodo"}
    assert set(r.comparacion_modelos) >= {"ultimo_periodo", "perfil_semanal"}


def test_historial_corto_baja_confianza_sin_backtesting():
    datos = _series(35)
    r = pronosticar_producto(datos.series[1], OBJ)
    assert r.confianza == "baja"
    assert r.metricas.ventanas == 0
    assert r.pronostico_final is not None
    assert any("insuficiente" in a.lower() for a in r.advertencias)


def test_historial_insuficiente_no_pronostica():
    datos = _series(10)
    r = pronosticar_producto(datos.series[1], OBJ)
    assert r.pronostico_final is None and r.confianza == "insuficiente" and r.metodo_final == "sin_datos"


def test_no_usa_datos_futuros():
    filas = ventas_sinteticas(120, FIN)
    filas.append({"producto_id": 1, "nombre": "Pepperoni", "fecha": (FIN + timedelta(days=3)).isoformat(), "cantidad": 99999})
    datos = construir_series([VentaDia(**f) for f in filas], FIN)
    assert any("posteriores" in a for a in datos.advertencias)
    assert datos.series[1].valores.max() < 1000


def test_duplicados_se_agregan_y_producto_nuevo_se_marca():
    filas = ventas_sinteticas(100, FIN, base={1: ("A", 10)})
    filas += [dict(filas[-1])]  # duplicado del ultimo dia: se suma
    filas += [{"producto_id": 9, "nombre": "Nueva", "fecha": (FIN - timedelta(days=5)).isoformat(), "cantidad": 3}]
    datos = construir_series([VentaDia(**f) for f in filas], FIN)
    assert datos.series[1].valores[-1] == pytest.approx(filas[-2]["cantidad"] * 2)
    r = pronosticar_producto(datos.series[9], OBJ)
    assert r.confianza == "insuficiente"


def test_serie_de_ceros_no_rompe():
    filas = ventas_sinteticas(100, FIN, base={1: ("A", 10)})
    filas += [{"producto_id": 5, "nombre": "Sin ventas recientes", "fecha": (FIN - timedelta(days=99)).isoformat(), "cantidad": 1}]
    datos = construir_series([VentaDia(**f) for f in filas], FIN)
    r = pronosticar_producto(datos.series[5], OBJ)
    assert r.pronostico_final is not None and r.pronostico_final >= 0
