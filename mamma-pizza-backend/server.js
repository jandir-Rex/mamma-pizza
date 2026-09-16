const http = require("http");
const app = require("./src/app");
const { port } = require("./src/config/env");
const { initSockets } = require("./src/sockets");

const server = http.createServer(app);
initSockets(server);

server.listen(port, () => {
  console.log(`🍕 Servidor corriendo en http://localhost:${port}`);
});