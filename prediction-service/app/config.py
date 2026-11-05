"""Configuracion del servicio (variables de entorno). Los secretos nunca se registran en logs."""
import os
from dataclasses import dataclass
from pathlib import Path


def cargar_env(ruta: Path | None = None) -> None:
    """Carga un .env sencillo (KEY=VALUE) sin pisar variables ya definidas."""
    ruta = ruta or Path(__file__).resolve().parent.parent / ".env"
    if not ruta.exists():
        return
    for linea in ruta.read_text(encoding="utf-8").splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#") or "=" not in linea:
            continue
        clave, valor = linea.split("=", 1)
        os.environ.setdefault(clave.strip(), valor.strip().strip('"').strip("'"))


@dataclass(frozen=True)
class Settings:
    service_key: str
    gemini_api_key: str
    gemini_model: str
    ai_timeout_s: float


def get_settings() -> Settings:
    return Settings(
        service_key=os.environ.get("SERVICE_API_KEY", ""),
        gemini_api_key=os.environ.get("GEMINI_API_KEY", ""),
        gemini_model=os.environ.get("GEMINI_MODEL", "gemini-3.8-flash"),
        ai_timeout_s=float(os.environ.get("AI_TIMEOUT_SECONDS", "25")),
    )
