import { env } from "./env.js";
import sql from "mssql";

const basePoolConfig = {
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

const sqlConfig = {
  ...basePoolConfig,
  server: env.DB_SERVER,
  port: env.DB_PORT,
  database: env.DB_NAME,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  options: {
    encrypt: env.DB_ENCRYPT,
    trustServerCertificate: env.DB_TRUST_SERVER_CERTIFICATE
  }
};

let poolPromise: Promise<any> | null = null;

export const getPool = async () => {
  if (!poolPromise) {
    poolPromise = new sql.ConnectionPool(sqlConfig).connect();
  }
  return poolPromise;
};

export { sql };
