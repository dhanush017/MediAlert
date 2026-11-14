// MediAlert backend entry point.

import { buildServer } from "./server.js";

export const APP_NAME = "MediAlert";

const port = Number(process.env.PORT ?? 3000);

buildServer().listen(port, () => {
  console.log(`${APP_NAME} backend listening on port ${port}`);
});
