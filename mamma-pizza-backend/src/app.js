const express = require("express");
const cors = require("cors");
const errorHandler = require("./middlewares/error.middleware");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", mensaje: "Mamma Pizza API funcionando" });
});

app.use("/api/auth", require("./modules/auth/auth.routes"));
app.use("/api/productos", require("./modules/productos/productos.routes"));
app.use("/api/pedidos", require("./modules/pedidos/pedidos.routes"));
app.use("/api/mesas", require("./modules/mesas/mesas.routes"));
app.use("/api/repartidores", require("./modules/repartidores/repartidores.routes"));
app.use("/api/agregados", require("./modules/agregados/agregados.routes")); 

app.use((req, res) => {
  res.status(404).json({ error: "Ruta no encontrada" });
});

app.use(errorHandler);

module.exports = app;