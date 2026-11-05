"""Motor B (IA cloud): opcional e independiente. Si falla, el resto del servicio sigue funcionando."""
import math
import time
from collections import defaultdict
from datetime import date

from pydantic import BaseModel, Field, ValidationError

from ..config import Settings
from ..data import DatosPreparados
from ..schemas import AnalisisIA, EstadoMotor, PronosticoProducto
from . import gemini
from .prompts import construir_prompt


class _Pron(BaseModel):
    producto_id: int
    cantidad: float


class _Respuesta(BaseModel):
    resumen: str = Field(max_length=2000)
    tendencias: list[str] = Field(default_factory=list, max_length=10)
    alertas: list[str] = Field(default_factory=list, max_length=10)
    recomendaciones: list[str] = Field(default_factory=list, max_length=10)
    pronostico_ia: list[_Pron] = Field(default_factory=list, max_length=500)


def _ventas_mensuales(datos: DatosPreparados, max_meses: int = 8) -> dict[int, dict[str, float]]:
    salida: dict[int, dict[str, float]] = {}
    for pid, s in datos.series.items():
        acum: dict[str, float] = defaultdict(float)
        for f, v in zip(s.fechas, s.valores):
            acum[f"{f.year}-{f.month:02d}"] += float(v)
        meses = sorted(acum)[-max_meses:]
        salida[pid] = {m: round(acum[m], 1) for m in meses}
    return salida


def analizar_con_ia(
    settings: Settings,
    habilitada: bool,
    datos: DatosPreparados,
    productos: list[PronosticoProducto],
    periodo_inicio: date,
    periodo_fin: date,
) -> tuple[EstadoMotor, AnalisisIA | None, dict[int, float]]:
    """Devuelve (estado del motor, analisis, pronosticos numericos de la IA por producto)."""
    if not habilitada:
        return EstadoMotor(estado="deshabilitado", detalle="IA deshabilitada por configuracion"), None, {}
    if not settings.gemini_api_key:
        return EstadoMotor(estado="no_disponible", detalle="Sin GEMINI_API_KEY configurada", proveedor="gemini"), None, {}
    if not productos:
        return EstadoMotor(estado="omitido", detalle="No hay productos para analizar", proveedor="gemini"), None, {}

    mensuales = _ventas_mensuales(datos)
    contexto = {
        "periodo_objetivo": {"inicio": periodo_inicio.isoformat(), "fin": periodo_fin.isoformat()},
        "productos": [
            {
                "producto_id": p.producto_id,
                "nombre": p.nombre,
                "ventas_mensuales": mensuales.get(p.producto_id, {}),
                "ventas_periodo_anterior": p.ventas_periodo_anterior,
                "pronostico_estadistico": p.pronostico_estadistico,
                "confianza": p.confianza,
            }
            for p in productos[:60]  # limite de tamano enviado
        ],
        "advertencias_datos": datos.advertencias[:5],
    }
    inicio = time.monotonic()
    try:
        bruto = gemini.generar_json(construir_prompt(contexto), settings.gemini_api_key, settings.gemini_model, settings.ai_timeout_s)
        resp = _Respuesta.model_validate(bruto)
    except gemini.ErrorProveedor as exc:
        return EstadoMotor(estado="error", detalle=str(exc), proveedor="gemini", modelo=settings.gemini_model,
                           latencia_ms=int((time.monotonic() - inicio) * 1000)), None, {}
    except (ValidationError, TypeError, ValueError):
        return EstadoMotor(estado="error", detalle="La IA devolvio una respuesta con formato invalido (descartada)", proveedor="gemini",
                           modelo=settings.gemini_model, latencia_ms=int((time.monotonic() - inicio) * 1000)), None, {}

    ids_validos = {p.producto_id for p in productos}
    numericos: dict[int, float] = {}
    for item in resp.pronostico_ia:  # validar: producto conocido, finito y no negativo
        if item.producto_id in ids_validos and math.isfinite(item.cantidad) and 0 <= item.cantidad <= 1_000_000:
            numericos[item.producto_id] = round(item.cantidad, 1)

    estado = EstadoMotor(estado="completado", proveedor="gemini", modelo=settings.gemini_model,
                         latencia_ms=int((time.monotonic() - inicio) * 1000))
    analisis = AnalisisIA(resumen=resp.resumen, tendencias=resp.tendencias, alertas=resp.alertas, recomendaciones=resp.recomendaciones)
    return estado, analisis, numericos
