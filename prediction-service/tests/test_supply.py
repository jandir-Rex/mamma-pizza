import pytest

from app.schemas import InventarioIngrediente, RecetaLinea
from app.supply import UnidadIncompatible, calcular_abastecimiento, convertir


def test_conversiones():
    assert convertir(250, "g", "kg") == pytest.approx(0.25)
    assert convertir(2, "kg", "g") == 2000
    assert convertir(500, "ml", "l") == pytest.approx(0.5)
    assert convertir(1, "docena", "u") == 12
    assert convertir(3, "Kilos", "kg") == 3


def test_unidades_incompatibles():
    with pytest.raises(UnidadIncompatible):
        convertir(1, "kg", "l")
    with pytest.raises(UnidadIncompatible):
        convertir(1, "caja", "kg")


def test_ejemplo_del_plan_harina():
    """Plan 11.2: necesidad 25 kg, merma 1 kg (4%), seguridad 2, inventario 8, pendientes 1 -> compra 19 kg."""
    recetas = [RecetaLinea(producto_id=1, ingrediente_id=10, ingrediente="Harina", cantidad=250, unidad="g")]
    inv = [InventarioIngrediente(ingrediente_id=10, ingrediente="Harina", cantidad=8, unidad="kg",
                                 compras_pendientes=1, stock_seguridad=2, merma_pct=4)]
    res, adv = calcular_abastecimiento({1: 100}, {1: "Pepperoni"}, recetas, inv)
    h = res[0]
    assert h.necesidad_bruta == pytest.approx(25)
    assert h.merma == pytest.approx(1)
    assert h.compra_sugerida == pytest.approx(19)
    assert h.unidad == "kg"
    assert h.alerta_faltante is True
    assert adv == []


def test_compra_nunca_negativa():
    recetas = [RecetaLinea(producto_id=1, ingrediente_id=10, ingrediente="Harina", cantidad=250, unidad="g")]
    inv = [InventarioIngrediente(ingrediente_id=10, ingrediente="Harina", cantidad=500, unidad="kg")]
    res, _ = calcular_abastecimiento({1: 100}, {1: "Pepperoni"}, recetas, inv)
    assert res[0].compra_sugerida == 0
    assert res[0].alerta_faltante is False


def test_ingredientes_compartidos_se_suman():
    recetas = [
        RecetaLinea(producto_id=1, ingrediente_id=10, ingrediente="Mozzarella", cantidad=150, unidad="g"),
        RecetaLinea(producto_id=2, ingrediente_id=10, ingrediente="Mozzarella", cantidad=100, unidad="g"),
    ]
    inv = [InventarioIngrediente(ingrediente_id=10, ingrediente="Mozzarella", cantidad=0, unidad="kg")]
    res, _ = calcular_abastecimiento({1: 100, 2: 50}, {1: "A", 2: "B"}, recetas, inv)
    assert res[0].necesidad_bruta == pytest.approx(100 * 0.15 + 50 * 0.1)


def test_sin_recetas_advierte():
    res, adv = calcular_abastecimiento({1: 10}, {1: "A"}, [], [])
    assert res == [] and "recetas" in adv[0].lower()


def test_producto_sin_receta_y_unidad_incompatible_se_advierten():
    recetas = [RecetaLinea(producto_id=1, ingrediente_id=10, ingrediente="Salsa", cantidad=80, unidad="g")]
    inv = [InventarioIngrediente(ingrediente_id=10, ingrediente="Salsa", cantidad=1, unidad="l")]
    res, adv = calcular_abastecimiento({1: 10, 2: 5}, {1: "A", 2: "Sin receta"}, recetas, inv)
    assert res == []  # g (masa) vs l (volumen): omitido, no se mezcla
    assert any("omitido" in a for a in adv)
    assert any("Sin receta" in a for a in adv)
