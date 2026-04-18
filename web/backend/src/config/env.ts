import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { z } from "zod";

const currentFile = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFile);
const rootEnvPath = path.resolve(currentDir, "../../../.env");

dotenv.config({ path: rootEnvPath });
dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(4000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  FRONTEND_URL: z.string().default("http://localhost:5173"),
  JWT_SECRET: z.string().min(8),
  JWT_EXPIRES_IN: z.string().default("8h"),
  DB_AUTH_TYPE: z.enum(["windows", "sql"]).default("windows"),
  DB_SERVER: z.string().min(1),
  DB_PORT: z.coerce.number().default(1433),
  DB_INSTANCE: z.string().optional(),
  DB_NAME: z.string().min(1),
  DB_USER: z.string().optional(),
  DB_PASSWORD: z.string().optional(),
  DB_DRIVER: z.string().default("ODBC Driver 18 for SQL Server"),
  DB_ENCRYPT: z
    .string()
    .default("false")
    .transform((value) => value === "true"),
  DB_TRUST_SERVER_CERTIFICATE: z
    .string()
    .default("true")
    .transform((value) => value === "true")
});

export const env = envSchema.parse(process.env);
