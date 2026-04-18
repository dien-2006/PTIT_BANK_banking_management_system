import { env } from "./env.js";

const sqlModule = env.DB_AUTH_TYPE === "windows" ? await import("mssql/msnodesqlv8") : await import("mssql");
const sql = sqlModule.default;

const basePoolConfig = {
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

const serverTarget = env.DB_INSTANCE ? `${env.DB_SERVER}\\${env.DB_INSTANCE}` : env.DB_SERVER;

const sqlConfig =
  env.DB_AUTH_TYPE === "windows"
    ? {
        ...basePoolConfig,
        server: env.DB_SERVER,
        database: env.DB_NAME,
        driver: env.DB_DRIVER,
        options: {
          trustedConnection: true,
          trustServerCertificate: env.DB_TRUST_SERVER_CERTIFICATE,
          encrypt: env.DB_ENCRYPT,
          instanceName: env.DB_INSTANCE
        },
        connectionString: [
          `Driver={${env.DB_DRIVER}}`,
          `Server=${env.DB_INSTANCE ? serverTarget : env.DB_SERVER}`,
          `Database=${env.DB_NAME}`,
          "Trusted_Connection=Yes",
          `Encrypt=${env.DB_ENCRYPT ? "Yes" : "No"}`,
          `TrustServerCertificate=${env.DB_TRUST_SERVER_CERTIFICATE ? "Yes" : "No"}`
        ].join(";")
      }
    : {
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
