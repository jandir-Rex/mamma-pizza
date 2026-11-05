"""Microservicio de prediccion de ventas y abastecimiento (FastAPI). Servicio PRIVADO: solo lo llama el backend Node."""
import logging

from fastapi import Depends, FastAPI

from .config import cargar_env, get_settings
from .orquestador import VERSION, analizar
from .schemas import AnalisisRequest, AnalisisResponse
from .security import exigir_clave_de_servicio

cargar_env()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("prediccion")

app = FastAPI(title="Mamma Pizza - Prediccion y abastecimiento", version=VERSION, docs_url=None, redoc_url=None)


@app.get("/health")
def health():
    s = get_settings()
    return {"status": "ok", "version": VERSION, "ia_configurada": bool(s.gemini_api_key), "clave_de_servicio_configurada": bool(s.service_key)}


@app.post("/internal/intelligence/analyze", response_model=AnalisisResponse, dependencies=[Depends(exigir_clave_de_servicio)])
def analizar_endpoint(req: AnalisisRequest) -> AnalisisResponse:
    resultado = analizar(req, get_settings())
    log.info("analisis completado: %s productos, estado=%s, ia=%s", len(resultado.productos), resultado.estado, resultado.motores["ia_cloud"].estado)
    return resultado
