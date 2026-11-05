// Cliente HTTP privado hacia el microservicio Python. Node 18+ (fetch nativo).
function config() {
  return {
    base: (process.env.PREDICTION_SERVICE_URL || "http://127.0.0.1:8000").replace(/\/+$/, ""),
    clave: process.env.PREDICTION_SERVICE_KEY || "",
  };
}

function crearError(mensaje, status) {
  const e = new Error(mensaje);
  e.status = status;
  return e;
}

async function pedir(ruta, { method = "GET", body, timeoutMs = 20000, auth = true } = {}) {
  const { base, clave } = config();
  if (auth && !clave) {
    throw crearError("Falta PREDICTION_SERVICE_KEY en el .env del backend", 500);
  }
  const controlador = new AbortController();
  const temporizador = setTimeout(() => controlador.abort(), timeoutMs);
  try {
    const res = await fetch(`${base}${ruta}`, {
      method,
      headers: { "Content-Type": "application/json", ...(auth ? { "X-Service-Key": clave } : {}) },
      body: body ? JSON.stringify(body) : undefined,
      signal: controlador.signal,
    });
    if (res.ok) return await res.json();

    const texto = await res.text().catch(() => "");
    if (res.status === 401 || res.status === 503) {
      throw crearError("El servicio de predicción rechazó la solicitud: revisa que PREDICTION_SERVICE_KEY coincida con SERVICE_API_KEY.", 502);
    }
    if (res.status === 422) {
      throw crearError(`El servicio de predicción rechazó los datos enviados: ${texto.slice(0, 300)}`, 502);
    }
    throw crearError(`El servicio de predicción respondió con error ${res.status}.`, 502);
  } catch (err) {
    if (err.status) throw err;
    if (err.name === "AbortError") {
      throw crearError("El servicio de predicción tardó demasiado en responder.", 504);
    }
    throw crearError("El servicio de predicción no está disponible. Las ventas y pedidos no se ven afectados.", 503);
  } finally {
    clearTimeout(temporizador);
  }
}

const health = () => pedir("/health", { auth: false, timeoutMs: 4000 });
const analizar = (payload) => pedir("/internal/intelligence/analyze", { method: "POST", body: payload, timeoutMs: 120000 });

module.exports = { health, analizar };
