import json

import httpx
from fastapi.testclient import TestClient

from app.main import app
from tests.conftest import ventas_sinteticas
from datetime import date

cliente = TestClient(app)
H = {"X-Service-Key": "clave-de-prueba"}
FIN = date(2026, 11, 2)


def _payload(dias=200, recetas=None, inventario=None, ia=True):
    return {
        "periodo": {"inicio": "2026-12-01", "fin": "2026-12-31"},
        "fecha_corte": FIN.isoformat(),
        "ventas": ventas_sinteticas(dias, FIN),
        "recetas": recetas or [],
        "inventario": inventario or [],
        "config": {"ia_habilitada": ia},
    }


def test_health_publico():
    r = cliente.get("/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"


def test_exige_clave_de_servicio():
    assert cliente.post("/internal/intelligence/analyze", json=_payload()).status_code == 401
    assert cliente.post("/internal/intelligence/analyze", json=_payload(), headers={"X-Service-Key": "mala"}).status_code == 401


def test_analisis_completo_sin_ia():
    receta = [{"producto_id": 1, "ingrediente_id": 10, "ingrediente": "Harina", "cantidad": 250, "unidad": "g"}]
    inv = [{"ingrediente_id": 10, "ingrediente": "Harina", "cantidad": 8, "unidad": "kg", "compras_pendientes": 1, "stock_seguridad": 2, "merma_pct": 4}]
    r = cliente.post("/internal/intelligence/analyze", json=_payload(recetas=receta, inventario=inv), headers=H)
    assert r.status_code == 200, r.text
    d = r.json()
    assert d["motores"]["estadistico"]["estado"] == "completado"
    assert d["motores"]["ia_cloud"]["estado"] == "no_disponible"  # sin GEMINI_API_KEY
    assert d["estado"] == "parcial"
    assert len(d["productos"]) == 2
    assert all(p["metodo_final"] == "estadistico" for p in d["productos"])
    assert d["evaluacion"]["combinacion_habilitada"] is False
    harina = d["ingredientes"][0]
    assert harina["compra_sugerida"] >= 0 and harina["unidad"] == "kg"
    assert any("Analisis de IA no disponible" in a for a in d["advertencias"])


def test_ia_deshabilitada_es_completado():
    d = cliente.post("/internal/intelligence/analyze", json=_payload(ia=False), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "deshabilitado" and d["estado"] == "completado"


def test_validacion_de_entrada():
    p = _payload(); p["periodo"]["fin"] = "2026-11-01"
    assert cliente.post("/internal/intelligence/analyze", json=p, headers=H).status_code == 422
    p = _payload(); p["ventas"][0]["cantidad"] = -5
    assert cliente.post("/internal/intelligence/analyze", json=p, headers=H).status_code == 422


def test_sin_ventas_no_falla():
    p = _payload(); p["ventas"] = []
    d = cliente.post("/internal/intelligence/analyze", json=p, headers=H).json()
    assert d["productos"] == [] and any("No hay ventas" in a for a in d["advertencias"])


# ---- IA: respuestas simuladas del proveedor ----
def _con_ia(monkeypatch, respuesta=None, status=200, texto=None):
    monkeypatch.setenv("GEMINI_API_KEY", "clave-falsa")

    def falso_post(url, json=None, headers=None, timeout=None):
        assert "clave-falsa" not in url  # la clave va en cabecera, no en la URL
        if texto is not None:
            cuerpo = {"candidates": [{"content": {"parts": [{"text": texto}]}}]}
        else:
            cuerpo = {"candidates": [{"content": {"parts": [{"text": __import__("json").dumps(respuesta)}]}}]}
        return httpx.Response(status, json=cuerpo, request=httpx.Request("POST", url))

    monkeypatch.setattr("app.ai.gemini.httpx.post", falso_post)
    monkeypatch.setattr("app.ai.gemini.time.sleep", lambda s: None)


def test_ia_ok_se_valida_y_no_cambia_el_pronostico_final(monkeypatch):
    _con_ia(monkeypatch, {"resumen": "Demanda estable.", "tendencias": ["t"], "alertas": [], "recomendaciones": ["Revisar stock"],
                          "pronostico_ia": [{"producto_id": 1, "cantidad": 99999}, {"producto_id": 2, "cantidad": -4}, {"producto_id": 77, "cantidad": 5}]})
    d = cliente.post("/internal/intelligence/analyze", json=_payload(), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "completado" and d["estado"] == "completado"
    p1 = next(p for p in d["productos"] if p["producto_id"] == 1)
    p2 = next(p for p in d["productos"] if p["producto_id"] == 2)
    assert p1["pronostico_ia"] == 99999.0                      # cifra valida (finita, no negativa) se guarda para evaluarla
    assert p1["pronostico_final"] == p1["pronostico_estadistico"]  # pero NO reemplaza al estadistico
    assert p2["pronostico_ia"] is None                          # negativa: descartada
    assert any(x["tipo"] == "discrepancia_motores" for x in d["recomendaciones"])
    assert any(x["origen"] == "ia" for x in d["recomendaciones"])


def test_ia_json_invalido_se_descarta(monkeypatch):
    _con_ia(monkeypatch, texto="esto no es json {")
    d = cliente.post("/internal/intelligence/analyze", json=_payload(), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "error" and d["estado"] == "parcial"
    assert len(d["productos"]) == 2  # el motor estadistico no se afecta


def test_ia_esquema_invalido_se_descarta(monkeypatch):
    _con_ia(monkeypatch, {"resumen": 123, "tendencias": "no-es-lista"})
    d = cliente.post("/internal/intelligence/analyze", json=_payload(), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "error"


def test_ia_cuota_agotada_no_rompe(monkeypatch):
    _con_ia(monkeypatch, respuesta={}, status=429)
    d = cliente.post("/internal/intelligence/analyze", json=_payload(), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "error" and "429" in d["motores"]["ia_cloud"]["detalle"]
    assert d["productos"][0]["pronostico_final"] is not None


def test_ia_sin_respuesta_por_timeout(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "clave-falsa")

    def lanza(*a, **k):
        raise httpx.ReadTimeout("lento")

    monkeypatch.setattr("app.ai.gemini.httpx.post", lanza)
    monkeypatch.setattr("app.ai.gemini.time.sleep", lambda s: None)
    d = cliente.post("/internal/intelligence/analyze", json=_payload(), headers=H).json()
    assert d["motores"]["ia_cloud"]["estado"] == "error" and "tiempo" in d["motores"]["ia_cloud"]["detalle"]


def test_serie_historica_para_graficas():
    d = cliente.post("/internal/intelligence/analyze", json=_payload(dias=200, ia=False), headers=H).json()
    s = d["serie_historica"]
    assert len(s["meses"]) >= 6 and len(s["meses"]) == len(s["total"])
    # el total mensual coincide con la suma de productos (top + otros)
    for i, total in enumerate(s["total"]):
        assert abs(sum(p["valores"][i] for p in s["por_producto"]) - total) < 0.2
    assert s["semanal"]["dias"][0] == "Lun" and len(s["semanal"]["promedio"]) == 7
    # patron sintetico: sabado y domingo son los dias mas fuertes
    assert max(range(7), key=lambda i: s["semanal"]["promedio"][i]) in (5, 6)
    assert len(s["diaria"]["fechas"]) == 98 and len(s["diaria"]["total"]) == 98
    assert set(s["mensual_por_producto"]) == {"1", "2"} and all(len(v) == len(s["meses"]) for v in s["mensual_por_producto"].values())
    assert s["ultimo_mes_parcial"] is True  # 2 de noviembre: mes incompleto
    assert s["primer_mes_parcial"] is True  # el historial sintetico empieza a mitad de mes


def test_serie_historica_vacia_sin_ventas():
    p = _payload(); p["ventas"] = []
    assert cliente.post("/internal/intelligence/analyze", json=p, headers=H).json()["serie_historica"] == {}


def test_no_compara_variaciones_con_historial_corto():
    corto = cliente.post("/internal/intelligence/analyze", json=_payload(dias=35, ia=False), headers=H).json()
    assert corto["datos"]["variacion_comparable"] is False
    assert not any(r["tipo"] in ("crecimiento", "caida") for r in corto["recomendaciones"])
    largo = cliente.post("/internal/intelligence/analyze", json=_payload(dias=200, ia=False), headers=H).json()
    assert largo["datos"]["variacion_comparable"] is True and largo["datos"]["dias_periodo"] == 31
