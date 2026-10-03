export const API_BASE_URL = (
  import.meta.env.VITE_API_URL ?? "http://localhost:4000/api"
).replace(/\/+$/, "");
export const API_ORIGIN = new URL(API_BASE_URL).origin;

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  const token = localStorage.getItem("token");

  if (options.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });
  const responseText = await response.text();
  const data: unknown = responseText ? JSON.parse(responseText) : null;

  if (!response.ok) {
    // Si el backend dice que el token es inválido o no tiene permisos (401)
    if (response.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("usuario");
      window.location.href = "/login"; // Expulsado automáticamente
      return Promise.reject(new Error("Sesión expirada o no autorizada"));
    }

    const message =
      typeof data === "object" && data !== null && "error" in data
        ? String(data.error)
        : "No se pudo completar la solicitud";
    throw new Error(message);
  }

  return data as T;
}