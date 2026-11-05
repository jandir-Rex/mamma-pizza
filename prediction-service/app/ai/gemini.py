"""Cliente minimo de la API REST de Gemini (sin SDK). La clave nunca se registra en logs."""
import json
import time

import httpx

URL = "https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent"


class ErrorProveedor(Exception):
    pass


def generar_json(prompt: str, api_key: str, modelo: str, timeout_s: float, intentos: int = 2) -> dict:
    cuerpo = {
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json", "maxOutputTokens": 2048},
    }
    cabeceras = {"x-goog-api-key": api_key, "Content-Type": "application/json"}
    ultimo_error = "desconocido"
    for intento in range(intentos):
        try:
            r = httpx.post(URL.format(modelo=modelo), json=cuerpo, headers=cabeceras, timeout=timeout_s)
        except httpx.TimeoutException:
            ultimo_error = "tiempo de espera agotado"
        except httpx.HTTPError as exc:
            ultimo_error = f"error de red ({type(exc).__name__})"
        else:
            if r.status_code == 200:
                try:
                    texto = r.json()["candidates"][0]["content"]["parts"][0]["text"]
                    return json.loads(texto)
                except (KeyError, IndexError, ValueError, TypeError) as exc:
                    raise ErrorProveedor(f"respuesta no es JSON valido ({type(exc).__name__})") from exc
            if r.status_code == 429:
                ultimo_error = "cuota o limite de solicitudes agotado (429)"
            elif r.status_code in (401, 403):
                raise ErrorProveedor(f"clave rechazada por el proveedor ({r.status_code})")
            elif r.status_code == 404:
                raise ErrorProveedor("modelo no disponible para esta cuenta (404); revisa GEMINI_MODEL")
            elif r.status_code >= 500:
                ultimo_error = f"error del proveedor ({r.status_code})"
            else:
                raise ErrorProveedor(f"error {r.status_code}")
        if intento < intentos - 1:
            time.sleep(1.5)
    raise ErrorProveedor(ultimo_error)
