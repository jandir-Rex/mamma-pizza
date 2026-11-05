# Microservicio de prediccion y abastecimiento (Mamma Pizza)

Servicio **privado** (FastAPI) que el backend Node llama para:
1. Pronosticar las unidades de cada producto del mes siguiente (motor estadistico, autonomo).
2. Pedir un analisis opcional a una IA en la nube (Gemini). Si falla o no hay clave, todo lo demas sigue funcionando.
3. Calcular ingredientes y compras sugeridas de forma determinista (recetas + inventario).

## Ejecutar (desarrollo)
```bash
python -m venv .venv
.venv/Scripts/activate        # Windows PowerShell: .venv\Scripts\Activate.ps1  |  Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # y editar SERVICE_API_KEY (igual que PREDICTION_SERVICE_KEY del backend)
uvicorn app.main:app --host 127.0.0.1 --port 8000
```
- `GET /health` (sin clave) y `POST /internal/intelligence/analyze` (cabecera `X-Service-Key`).
- No expongas el puerto 8000 a Internet: debe escuchar solo en 127.0.0.1.

## Pruebas
```bash
pip install -r requirements-dev.txt
python -m pytest -q
```

## Como decide
- Por producto se prueban: ultimo periodo, promedio movil, perfil semanal y ETS (Holt-Winters). Se elige por **backtesting** (WAPE) en hasta 4 ventanas historicas, sin usar datos futuros; un modelo mas complejo solo gana si mejora >5%.
- Menos de 14 dias de historial: no se pronostica. Sin historial para backtesting: metodo simple y confianza baja.
- La IA **no** decide cantidades. Su cifra numerica (si la da) se valida y se guarda para evaluarla contra ventas reales; **no se promedia** con el estadistico hasta tener evidencia.
- Compra sugerida = max(0, necesidad + merma + stock de seguridad - inventario - compras pendientes).

## Limitaciones conocidas
- No hay calendario de cierres: un dia sin ventas en todo el negocio cuenta como 0.
- Sin recetas/inventario registrados no hay plan de abastecimiento (el servicio lo indica).
- No se modelan promociones, feriados ni cambios de precio (no hay datos registrados).
