import { createServer, type Server } from "node:http";

export const APP_VERSION = "0.1.0";

/**
 * Builds the HTTP server. Kept separate from listen() so tests can bind to a random port.
 */
export function buildServer(): Server {
  return createServer((req, res) => {
    if (req.method === "GET" && req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "ok", version: APP_VERSION }));
      return;
    }

    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "not_found" }));
  });
}
