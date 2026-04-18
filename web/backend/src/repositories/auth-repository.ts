import { z } from "zod";
import { SqlRepository } from "./sql-repository.js";

const systemUserShape = z.object({
  UserID: z.union([z.number(), z.string()]).optional(),
  Username: z.string().optional(),
  RoleName: z.string().optional(),
  EmployeeID: z.union([z.number(), z.string()]).nullable().optional(),
  BranchID: z.union([z.number(), z.string()]).nullable().optional()
});

const customerOnlineUserShape = z.object({
  CustomerOnlineAccountID: z.union([z.number(), z.string()]).optional(),
  CustomerID: z.union([z.number(), z.string()]).nullable().optional(),
  Username: z.string().optional()
});

type LoginInput = {
  username: string;
  password: string;
};

export class AuthRepository extends SqlRepository {
  async systemLogin(payload: LoginInput) {
    const result = await this.executeProcedure("sp_SystemUserLogin", [
      { name: "Username", value: payload.username },
      { name: "PasswordHash", value: payload.password }
    ]);

    const row = result.recordset[0];

    if (!row) {
      return null;
    }

    const parsed = systemUserShape.parse(row);

    return {
      userId: parsed.UserID ?? payload.username,
      username: parsed.Username ?? payload.username,
      role: parsed.RoleName ?? "Admin",
      employeeId: parsed.EmployeeID ?? null,
      branchId: parsed.BranchID ?? null
    };
  }

  async customerOnlineLogin(payload: LoginInput) {
    const result = await this.executeProcedure("sp_CustomerOnlineLogin", [
      { name: "Username", value: payload.username },
      { name: "PasswordHash", value: payload.password }
    ]);

    const row = result.recordset[0];

    if (!row) {
      return null;
    }

    const parsed = customerOnlineUserShape.parse(row);

    return {
      userId: parsed.CustomerOnlineAccountID ?? payload.username,
      username: parsed.Username ?? payload.username,
      customerId: parsed.CustomerID ?? null
    };
  }
}
