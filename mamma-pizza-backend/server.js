const http = require("http");
const app = require("./src/app");
const { port } = require("./src/config/env");

const server = http.createServer(app);

server.listen(port, () => {
  console.log(`🍕 Servidor corriendo en http://localhost:${port}`);
});