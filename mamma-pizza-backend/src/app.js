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
app.use(errorHandler);

module.exports = app;