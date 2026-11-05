# Inicia el microservicio de prediccion (solo escucha en 127.0.0.1:8000)
Set-Location $PSScriptRoot
if (-not (Test-Path ".\.venv\Scripts\python.exe")) { Write-Host "Falta el entorno virtual. Ejecuta: python -m venv .venv ; .\.venv\Scripts\pip install -r requirements.txt" -ForegroundColor Red; exit 1 }
& .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
