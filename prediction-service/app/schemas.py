"""Esquemas de entrada y salida del microservicio."""
from datetime import date
from typing import Literal

from pydantic import BaseModel, Field, model_validator


# ----------------------------- ENTRADA -----------------------------
class Periodo(BaseModel):
    inicio: date
    fin: date

    @model_validator(mode="after")
    def _validar(self):
        if self.fin < self.inicio:
            raise ValueError("periodo.fin no puede ser anterior a periodo.inicio")
        if (self.fin - self.inicio).days > 92:
            raise ValueError("El periodo no puede superar 93 dias")
        return self


class VentaDia(BaseModel):
    producto_id: int
    nombre: str = Field(max_length=200)
    fecha: date
    cantidad: float = Field(ge=0)


class RecetaLinea(BaseModel):
    producto_id: int
    ingrediente_id: int
    ingrediente: str = Field(max_length=200)
    cantidad: float = Field(gt=0)
    unidad: str = Field(max_length=20)


class InventarioIngrediente(BaseModel):
    ingrediente_id: int
    ingrediente: str = Field(max_length=200)
    cantidad: float = Field(default=0, ge=0)
    unidad: str = Field(max_length=20)
    compras_pendientes: float = Field(default=0, ge=0)
    stock_seguridad: float = Field(default=0, ge=0)
    merma_pct: float = Field(default=0, ge=0, le=100)


class ConfigAnalisis(BaseModel):
    ia_habilitada: bool = True


class AnalisisRequest(BaseModel):
    periodo: Periodo
    fecha_corte: date
    ventas: list[VentaDia] = Field(max_length=300000)
    recetas: list[RecetaLinea] = Field(default_factory=list, max_length=20000)
    inventario: list[InventarioIngrediente] = Field(default_factory=list, max_length=5000)
    config: ConfigAnalisis = Field(default_factory=ConfigAnalisis)


# ----------------------------- SALIDA -----------------------------
Confianza = Literal["alta", "media", "baja", "insuficiente"]


class MetricasModelo(BaseModel):
    mae: float | None = None
    wape: float | None = None
    smape: float | None = None
    ventanas: int = 0
    horizonte_dias: int = 0


class PronosticoProducto(BaseModel):
    producto_id: int
    nombre: str
    ventas_periodo_anterior: float
    pronostico_estadistico: float | None
    limite_inferior: float | None = None
    limite_superior: float | None = None
    nivel_intervalo: float | None = None
    variacion_pct: float | None = None
    modelo: str | None
    metricas: MetricasModelo
    comparacion_modelos: dict[str, float | None] = Field(default_factory=dict)
    confianza: Confianza
    advertencias: list[str] = Field(default_factory=list)
    pronostico_ia: float | None = None
    pronostico_final: float | None
    metodo_final: Literal["estadistico", "sin_datos"]


class IngredienteNecesidad(BaseModel):
    ingrediente_id: int
    nombre: str
    unidad: str
    necesidad_bruta: float
    merma: float
    necesidad_ajustada: float
    stock_seguridad: float
    inventario_disponible: float
    compras_pendientes: float
    compra_sugerida: float
    alerta_faltante: bool
    detalle: list[str]


class Recomendacion(BaseModel):
    tipo: str
    severidad: Literal["info", "atencion", "critica"]
    mensaje: str
    fundamento: str
    origen: Literal["reglas", "ia"] = "reglas"


class EstadoMotor(BaseModel):
    estado: Literal["completado", "no_disponible", "deshabilitado", "error", "omitido"]
    detalle: str = ""
    proveedor: str | None = None
    modelo: str | None = None
    latencia_ms: int | None = None


class AnalisisIA(BaseModel):
    resumen: str
    tendencias: list[str] = Field(default_factory=list)
    alertas: list[str] = Field(default_factory=list)
    recomendaciones: list[str] = Field(default_factory=list)


class AnalisisResponse(BaseModel):
    version_servicio: str
    periodo: Periodo
    fecha_corte: date
    estado: Literal["completado", "parcial"]
    motores: dict[str, EstadoMotor]
    datos: dict
    productos: list[PronosticoProducto]
    ingredientes: list[IngredienteNecesidad]
    evaluacion: dict
    analisis_ia: AnalisisIA | None = None
    serie_historica: dict = Field(default_factory=dict)
    recomendaciones: list[Recomendacion]
    advertencias: list[str]
