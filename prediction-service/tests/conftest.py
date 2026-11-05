import os
import random
import sys
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ["SERVICE_API_KEY"] = "clave-de-prueba"
os.environ["GEMINI_API_KEY"] = ""


def ventas_sinteticas(dias: int, fin: date, base=None, semanal=None, ruido=2, semilla=1, tendencia=0.0):
    """Ventas diarias por producto con patron semanal (fines de semana mas altos)."""
    rnd = random.Random(semilla)
    base = base or {1: ("Pepperoni", 20), 2: ("Hawaiana", 10)}
    semanal = semanal or [0.7, 0.7, 0.8, 0.9, 1.2, 1.6, 1.5]
    filas = []
    for i in range(dias):
        f = fin - timedelta(days=dias - 1 - i)
        for pid, (nombre, nivel) in base.items():
            media = nivel * semanal[f.weekday()] * (1 + tendencia * i)
            cant = max(0, round(media + rnd.uniform(-ruido, ruido)))
            filas.append({"producto_id": pid, "nombre": nombre, "fecha": f.isoformat(), "cantidad": cant})
    return filas
