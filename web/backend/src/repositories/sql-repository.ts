import { getPool, sql } from "../config/db.js";

type SqlValue = string | number | boolean | Date | null;

type ProcedureInput = {
  name: string;
  type?: unknown;
  value: SqlValue;
};

export class SqlRepository {
  protected async executeProcedure(procedure: string, inputs: ProcedureInput[] = []) {
    const pool = await getPool();
    const request = pool.request();

    inputs.forEach((input) => {
      if (input.type) {
        request.input(input.name, input.type as never, input.value as never);
        return;
      }

      request.input(input.name, input.value as never);
    });

    return request.execute(procedure);
  }

  protected async executeQuery<T>(query: string, inputs: ProcedureInput[] = []) {
    const pool = await getPool();
    const request = pool.request();

    inputs.forEach((input) => {
      if (input.type) {
        request.input(input.name, input.type as never, input.value as never);
        return;
      }

      request.input(input.name, input.value as never);
    });

    const result = await request.query(query);
    return result.recordset;
  }
}
