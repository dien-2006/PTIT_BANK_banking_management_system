import { z } from "zod";
import { AuthRepository } from "../repositories/auth-repository.js";
import { signToken } from "../utils/jwt.js";

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1)
});

export class AuthService {
  constructor(private readonly repository: AuthRepository) {}

  async systemLogin(payload: unknown) {
    const data = loginSchema.parse(payload);
    const user = await this.repository.systemLogin(data);

    if (!user) {
      throw new Error("Invalid username or password");
    }

    const token = signToken({
      userId: user.userId,
      username: user.username,
      role: user.role,
      employeeId: user.employeeId,
      branchId: user.branchId
    });

    return { token, user };
  }

  async customerOnlineLogin(payload: unknown) {
    const data = loginSchema.parse(payload);
    const user = await this.repository.customerOnlineLogin(data);

    if (!user) {
      throw new Error("Invalid username or password");
    }

    const token = signToken({
      userId: user.userId,
      username: user.username,
      role: "Customer",
      customerId: user.customerId
    });

    return { token, user };
  }
}
