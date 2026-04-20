import { env } from "./env.js";
import sql from "mssql";
import sqlNative from "mssql/msnodesqlv8.js";

const basePoolConfig = {
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

const sqlAuthConfig = {
  ...basePoolConfig,
  server: env.DB_SERVER,
  port: env.DB_PORT,
  database: env.DB_NAME,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  options: {
    ...(env.DB_INSTANCE ? { instanceName: env.DB_INSTANCE } : {}),
    encrypt: env.DB_ENCRYPT,
    trustServerCertificate: env.DB_TRUST_SERVER_CERTIFICATE
  }
};

const windowsServerName = env.DB_INSTANCE ? `${env.DB_SERVER}\\${env.DB_INSTANCE}` : env.DB_SERVER;
const windowsConnectionString = [
  `Driver={${env.DB_DRIVER}}`,
  `Server=${windowsServerName}`,
  `Database=${env.DB_NAME}`,
  "Trusted_Connection=Yes",
  `Encrypt=${env.DB_ENCRYPT ? "Yes" : "No"}`,
  `TrustServerCertificate=${env.DB_TRUST_SERVER_CERTIFICATE ? "Yes" : "No"}`
].join(";");

const windowsAuthConfig = {
  ...basePoolConfig,
  connectionString: windowsConnectionString,
  options: {
    trustedConnection: true
  }
};

let poolPromise: Promise<any> | null = null;

export const getPool = async () => {
  if (!poolPromise) {
    poolPromise =
      env.DB_AUTH_TYPE === "windows"
        ? new sqlNative.ConnectionPool(windowsAuthConfig).connect()
        : new sql.ConnectionPool(sqlAuthConfig).connect();
  }
  return poolPromise;
};

export { sql };
