import type { Request, Response } from "express";
import { AuthService } from "../services/auth-service.js";

export class AuthController {
  constructor(private readonly service: AuthService) {}

  systemLogin = async (req: Request, res: Response) => {
    const result = await this.service.systemLogin(req.body);
    return res.json(result);
  };

  customerOnlineLogin = async (req: Request, res: Response) => {
    const result = await this.service.customerOnlineLogin(req.body);
    return res.json(result);
  };
}
