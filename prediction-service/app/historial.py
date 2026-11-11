"""Series historicas agregadas para graficas del panel (ventas por mes, por dia de la semana y diarias)."""
from collections import defaultdict
from datetime import date, timedelta

from .data import DatosPreparados

DIAS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]


def _meses_hasta(fecha_corte: date, n: int) -> list[tuple[int, int]]:
    y, m = fecha_corte.year, fecha_corte.month
    salida = []
    for _ in range(n):
        salida.append((y, m))
        m -= 1
        if m == 0:
            m, y = 12, y - 1
    salida.reverse()
    return salida


def construir_serie_historica(
    datos: DatosPreparados,
    fecha_corte: date,
    max_meses: int = 12,
    dias_recientes: int = 98,
    top_productos: int = 5,
) -> dict:
    if not datos.series:
        return {}

    total_dia: dict[date, float] = defaultdict(float)
    por_prod_mes: dict[int, dict[tuple[int, int], float]] = defaultdict(lambda: defaultdict(float))
    for pid, s in datos.series.items():
        for f, v in zip(s.fechas, s.valores):
            total_dia[f] += float(v)
            por_prod_mes[pid][(f.year, f.month)] += float(v)

    primero = min(total_dia)
    meses = [k for k in _meses_hasta(fecha_corte, max_meses) if k >= (primero.year, primero.month)]

    def suma_mes(pid: int, k: tuple[int, int]) -> float:
        return por_prod_mes[pid].get(k, 0.0)

    total = [round(sum(suma_mes(pid, k) for pid in por_prod_mes), 1) for k in meses]
    ranking = sorted(por_prod_mes, key=lambda pid: -sum(suma_mes(pid, k) for k in meses))
    top, resto = ranking[:top_productos], ranking[top_productos:]
    por_producto = [
        {"producto_id": pid, "nombre": datos.series[pid].nombre, "valores": [round(suma_mes(pid, k), 1) for k in meses]}
        for pid in top
    ]
    if resto:
        por_producto.append({
            "producto_id": None,
            "nombre": "Otros",
            "valores": [round(sum(suma_mes(pid, k) for pid in resto), 1) for k in meses],
        })

    # Serie mensual de TODAS las pizzas (para minigraficos de tendencia), maximo 80 productos
    mensual_por_producto = {
        str(pid): [round(suma_mes(pid, k), 1) for k in meses]
        for pid in ranking[:80]
    }

    # Patron semanal: promedio de unidades por dia de la semana en las ultimas 8 semanas
    desde_sem = max(primero, fecha_corte - timedelta(days=55))
    por_dia_sem: dict[int, list[float]] = defaultdict(list)
    d = desde_sem
    while d <= fecha_corte:
        por_dia_sem[d.weekday()].append(total_dia.get(d, 0.0))
        d += timedelta(days=1)
    promedio_sem = [round(sum(por_dia_sem[w]) / len(por_dia_sem[w]), 1) if por_dia_sem[w] else 0.0 for w in range(7)]

    # Ventas diarias recientes
    desde_dia = max(primero, fecha_corte - timedelta(days=dias_recientes - 1))
    fechas, totales = [], []
    d = desde_dia
    while d <= fecha_corte:
        fechas.append(d.isoformat())
        totales.append(round(total_dia.get(d, 0.0), 1))
        d += timedelta(days=1)

    return {
        "meses": [f"{y}-{m:02d}" for y, m in meses],
        "total": total,
        "por_producto": por_producto,
        "mensual_por_producto": mensual_por_producto,
        "primer_mes_parcial": primero.day > 1,
        "ultimo_mes_parcial": (fecha_corte + timedelta(days=1)).month == fecha_corte.month,
        "semanal": {"dias": DIAS, "promedio": promedio_sem, "dias_considerados": (fecha_corte - desde_sem).days + 1},
        "diaria": {"fechas": fechas, "total": totales},
    }
