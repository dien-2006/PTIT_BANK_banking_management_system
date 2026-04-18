import { app } from "./app.js";
import { env } from "./config/env.js";
import { getPool } from "./config/db.js";

const start = async () => {
  await getPool();

  app.listen(env.PORT, () => {
    console.log(`PTIT BANK API listening on port ${env.PORT}`);
  });
};

start().catch((error) => {
  console.error("Failed to start server", error);
  process.exit(1);
});
