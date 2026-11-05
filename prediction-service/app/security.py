"""Autenticacion entre servicios: solo el backend Node (con la clave compartida) puede llamar."""
import hmac

from fastapi import Header, HTTPException

from .config import get_settings


def exigir_clave_de_servicio(x_service_key: str | None = Header(default=None)) -> None:
    esperada = get_settings().service_key
    if not esperada:
        raise HTTPException(status_code=503, detail="Servicio sin SERVICE_API_KEY configurada")
    if not x_service_key or not hmac.compare_digest(x_service_key, esperada):
        raise HTTPException(status_code=401, detail="Clave de servicio invalida")
