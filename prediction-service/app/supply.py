"""Calculo DETERMINISTA de ingredientes y compras. La IA no interviene aqui.

necesidad_bruta   = suma(unidades pronosticadas del producto x cantidad del ingrediente en su receta)
necesidad_ajustada = necesidad_bruta + merma
compra_sugerida   = max(0, necesidad_ajustada + stock_seguridad - inventario_disponible - compras_pendientes)
"""
from collections import defaultdict

from .schemas import IngredienteNecesidad, InventarioIngrediente, RecetaLinea

# unidad -> (dimension, factor a la unidad base: g, ml o unidad)
_UNIDADES = {
    "mg": ("masa", 0.001), "g": ("masa", 1.0), "kg": ("masa", 1000.0),
    "ml": ("volumen", 1.0), "l": ("volumen", 1000.0),
    "unidad": ("conteo", 1.0), "docena": ("conteo", 12.0),
}
_ALIAS = {
    "gr": "g", "grs": "g", "gramo": "g", "gramos": "g",
    "kilo": "kg", "kilos": "kg", "kgs": "kg", "kilogramo": "kg", "kilogramos": "kg",
    "mililitro": "ml", "mililitros": "ml", "mls": "ml",
    "lt": "l", "lts": "l", "litro": "l", "litros": "l",
    "u": "unidad", "und": "unidad", "unid": "unidad", "unidades": "unidad", "uni": "unidad", "pza": "unidad", "pieza": "unidad", "piezas": "unidad",
    "docenas": "docena",
}


class UnidadIncompatible(ValueError):
    pass


def normalizar_unidad(u: str) -> str:
    x = u.strip().lower().rstrip(".")
    x = _ALIAS.get(x, x)
    if x not in _UNIDADES:
        raise UnidadIncompatible(f"Unidad desconocida: '{u}'")
    return x


def convertir(cantidad: float, de: str, a: str) -> float:
    d, a_ = normalizar_unidad(de), normalizar_unidad(a)
    dim_d, f_d = _UNIDADES[d]
    dim_a, f_a = _UNIDADES[a_]
    if dim_d != dim_a:
        raise UnidadIncompatible(f"No se puede convertir {de} a {a} ({dim_d} vs {dim_a})")
    return cantidad * f_d / f_a


def _r(x: float) -> float:
    return round(x + 0.0, 3)


def calcular_abastecimiento(
    pronosticos: dict[int, float],
    nombres_producto: dict[int, str],
    recetas: list[RecetaLinea],
    inventario: list[InventarioIngrediente],
) -> tuple[list[IngredienteNecesidad], list[str]]:
    advertencias: list[str] = []
    if not recetas:
        advertencias.append(
            "No hay recetas registradas: no se puede calcular el abastecimiento. Registra las recetas (ingredientes por pizza) para activarlo."
        )
        return [], advertencias

    inv = {i.ingrediente_id: i for i in inventario}
    recetas_por_prod: dict[int, list[RecetaLinea]] = defaultdict(list)
    for linea in recetas:
        recetas_por_prod[linea.producto_id].append(linea)

    sin_receta = [nombres_producto.get(pid, str(pid)) for pid, u in pronosticos.items() if u > 0 and pid not in recetas_por_prod]
    if sin_receta:
        advertencias.append("Productos con demanda prevista pero sin receta (su consumo NO esta incluido): " + ", ".join(sorted(sin_receta)) + ".")

    # unidad de calculo por ingrediente: la del inventario si existe; si no, la de su primera linea de receta
    unidad_ing: dict[int, str] = {}
    nombre_ing: dict[int, str] = {}
    for linea in recetas:
        nombre_ing.setdefault(linea.ingrediente_id, linea.ingrediente)
        unidad_ing.setdefault(linea.ingrediente_id, inv[linea.ingrediente_id].unidad if linea.ingrediente_id in inv else linea.unidad)

    bruta: dict[int, float] = defaultdict(float)
    aporte: dict[int, list[str]] = defaultdict(list)
    omitidos: set[int] = set()

    for pid, unidades in pronosticos.items():
        if unidades <= 0:
            continue
        for linea in recetas_por_prod.get(pid, []):
            ing = linea.ingrediente_id
            if ing in omitidos:
                continue
            try:
                por_unidad = convertir(linea.cantidad, linea.unidad, unidad_ing[ing])
            except UnidadIncompatible as exc:
                advertencias.append(f"Ingrediente '{linea.ingrediente}' omitido: {exc}.")
                omitidos.add(ing)
                continue
            consumo = unidades * por_unidad
            bruta[ing] += consumo
            aporte[ing].append(f"{nombres_producto.get(pid, pid)}: {unidades:g} x {por_unidad:g} {unidad_ing[ing]} = {_r(consumo):g} {unidad_ing[ing]}")

    salida: list[IngredienteNecesidad] = []
    for ing in sorted(bruta, key=lambda i: nombre_ing[i].lower()):
        if ing in omitidos:
            continue
        unidad = unidad_ing[ing]
        reg = inv.get(ing)
        if reg is None:
            advertencias.append(f"'{nombre_ing[ing]}' no tiene inventario registrado: se asume stock 0.")
            disp = pend = seg = 0.0
            merma_pct = 0.0
        else:
            try:
                disp = convertir(reg.cantidad, reg.unidad, unidad)
                pend = convertir(reg.compras_pendientes, reg.unidad, unidad)
                seg = convertir(reg.stock_seguridad, reg.unidad, unidad)
            except UnidadIncompatible as exc:
                advertencias.append(f"Ingrediente '{nombre_ing[ing]}' omitido: {exc}.")
                continue
            merma_pct = reg.merma_pct

        merma = bruta[ing] * merma_pct / 100.0
        ajustada = bruta[ing] + merma
        compra = max(0.0, ajustada + seg - disp - pend)
        detalle = list(aporte[ing]) + [
            f"Necesidad bruta = {_r(bruta[ing]):g} {unidad} (suma de las lineas anteriores)",
            f"+ merma {merma_pct:g}% = {_r(merma):g} {unidad} -> necesidad ajustada {_r(ajustada):g} {unidad}",
            f"+ stock de seguridad {_r(seg):g} - inventario {_r(disp):g} - compras pendientes {_r(pend):g}",
            f"= compra sugerida {_r(compra):g} {unidad} (nunca negativa)",
        ]
        salida.append(IngredienteNecesidad(
            ingrediente_id=ing, nombre=nombre_ing[ing], unidad=unidad,
            necesidad_bruta=_r(bruta[ing]), merma=_r(merma), necesidad_ajustada=_r(ajustada),
            stock_seguridad=_r(seg), inventario_disponible=_r(disp), compras_pendientes=_r(pend),
            compra_sugerida=_r(compra), alerta_faltante=(disp + pend) < ajustada, detalle=detalle,
        ))
    return salida, advertencias
