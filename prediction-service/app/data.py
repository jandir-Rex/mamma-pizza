"""Preparacion y validacion de datos: ventas diarias agregadas por producto."""
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, timedelta

import numpy as np

from .schemas import VentaDia


@dataclass
class Serie:
    producto_id: int
    nombre: str
    fechas: list[date]  # dias consecutivos, desde la primera venta del producto hasta la fecha de corte
    valores: np.ndarray  # unidades vendidas por dia (0 = sin ventas ese dia)
    primera_venta: date

    def __len__(self) -> int:
        return len(self.fechas)


@dataclass
class DatosPreparados:
    series: dict[int, Serie] = field(default_factory=dict)
    advertencias: list[str] = field(default_factory=list)
    meta: dict = field(default_factory=dict)


def construir_series(ventas: list[VentaDia], fecha_corte: date) -> DatosPreparados:
    """Agrega por producto/dia, descarta fechas posteriores al corte y rellena con 0 los dias sin ventas.

    Limitacion declarada: no hay calendario de apertura, asi que un dia sin ninguna venta en todo el
    negocio se trata como dia de cierre/sin demanda (0 ventas). No se distingue cierre de baja demanda.
    """
    res = DatosPreparados()
    por_prod_dia: dict[tuple[int, date], float] = defaultdict(float)
    nombres: dict[int, str] = {}
    primera: dict[int, date] = {}
    futuras = 0

    for v in ventas:
        if v.fecha > fecha_corte:
            futuras += 1
            continue
        por_prod_dia[(v.producto_id, v.fecha)] += v.cantidad
        nombres[v.producto_id] = v.nombre
        if v.producto_id not in primera or v.fecha < primera[v.producto_id]:
            primera[v.producto_id] = v.fecha

    if futuras:
        res.advertencias.append(f"Se ignoraron {futuras} registros de ventas posteriores a la fecha de corte.")

    if not por_prod_dia:
        res.advertencias.append("No hay ventas historicas validas antes de la fecha de corte.")
        res.meta = {"dias_historial": 0, "productos": 0, "dias_sin_ventas": 0}
        return res

    total_por_dia: dict[date, float] = defaultdict(float)
    for (_, f), c in por_prod_dia.items():
        total_por_dia[f] += c

    inicio = min(total_por_dia)
    n_dias = (fecha_corte - inicio).days + 1
    todas = [inicio + timedelta(days=i) for i in range(n_dias)]
    dias_sin_ventas = sum(1 for d in todas if total_por_dia.get(d, 0) <= 0)

    for pid, f0 in primera.items():
        idx0 = (f0 - inicio).days
        fechas = todas[idx0:]
        valores = np.array([por_prod_dia.get((pid, d), 0.0) for d in fechas], dtype=float)
        res.series[pid] = Serie(pid, nombres[pid], fechas, valores, f0)

    res.meta = {
        "dias_historial": n_dias,
        "inicio_historial": inicio.isoformat(),
        "fin_historial": fecha_corte.isoformat(),
        "productos": len(res.series),
        "dias_sin_ventas": dias_sin_ventas,
    }
    if dias_sin_ventas:
        res.advertencias.append(
            f"{dias_sin_ventas} de {n_dias} dias del historial no tienen ninguna venta; se tratan como dias sin demanda "
            "(no hay calendario de cierres)."
        )
    if n_dias < 60:
        res.advertencias.append(
            f"Solo hay {n_dias} dias de historial. Los pronosticos tienen confianza baja y no se pudo evaluar con backtesting completo."
        )
    return res
