import type { Request, Response } from "express";
import { BankingService } from "../services/banking-service.js";

export class BankingController {
  constructor(private readonly service: BankingService) {}

  getDashboard = async (_req: Request, res: Response) => {
    const [overview] = await this.service.getDashboardOverview();
    const [topCustomers, topBranches] = await Promise.all([
      this.service.getTopCustomers(),
      this.service.getTopBranches()
    ]);

    return res.json({
      overview,
      topCustomers,
      topBranches
    });
  };

  getCustomers = async (_req: Request, res: Response) => res.json(await this.service.getCustomers());

  addCustomer = async (req: Request, res: Response) => {
    const result = await this.service.addCustomer(req.body);
    return res.status(201).json(result.recordset ?? { message: "Customer created" });
  };

  registerOnlineAccount = async (req: Request, res: Response) => {
    const result = await this.service.registerOnlineAccount(req.body);
    return res.status(201).json(result.recordset ?? { message: "Online account created" });
  };

  getBranches = async (_req: Request, res: Response) => res.json(await this.service.getBranches());

  getAccountTypes = async (_req: Request, res: Response) => res.json(await this.service.getAccountTypes());

  getAccounts = async (_req: Request, res: Response) => res.json(await this.service.getAccounts());

  openAccount = async (req: Request, res: Response) => {
    const result = await this.service.openAccount(req.body);
    return res.status(201).json(result.recordset ?? { message: "Account opened" });
  };

  updateAccountStatus = async (req: Request, res: Response) => {
    const payload = {
      ...req.body,
      ChangedByType: req.body.ChangedByType ?? "Employee",
      EmployeeID: req.user?.employeeId ?? req.body.EmployeeID
    };
    const result = await this.service.updateAccountStatus(payload);
    return res.json(result.recordset ?? { message: "Account status updated" });
  };

  deposit = async (req: Request, res: Response) => {
    const payload = { ...req.body, EmployeeID: req.user?.employeeId ?? req.body.EmployeeID ?? req.body.PerformedBy };
    const result = await this.service.deposit(payload);
    return res.json(result.recordset ?? { message: "Deposit completed" });
  };

  withdraw = async (req: Request, res: Response) => {
    const payload = { ...req.body, EmployeeID: req.user?.employeeId ?? req.body.EmployeeID ?? req.body.PerformedBy };
    const result = await this.service.withdraw(payload);
    return res.json(result.recordset ?? { message: "Withdrawal completed" });
  };

  transfer = async (req: Request, res: Response) => {
    const payload = { ...req.body, EmployeeID: req.user?.employeeId ?? req.body.EmployeeID ?? req.body.PerformedBy };
    const result = await this.service.transfer(payload);
    return res.json(result.recordset ?? { message: "Transfer completed" });
  };

  getTransactionHistory = async (req: Request, res: Response) => {
    const result = await this.service.getTransactionHistory(req.query);
    const rows = (result.recordset ?? []).map((row: Record<string, unknown>) => ({
      ...row,
      AccountID: row.SourceAccountID ?? row.DestinationAccountID ?? null,
      TransactionType: row.TransactionType ?? row.TransactionTypeName ?? null
    }));
    return res.json(rows);
  };

  getCards = async (_req: Request, res: Response) => res.json(await this.service.getCards());

  issueCard = async (req: Request, res: Response) => {
    const result = await this.service.issueCard(req.body);
    return res.status(201).json(result.recordset ?? { message: "Card issued" });
  };

  getLoans = async (_req: Request, res: Response) => res.json(await this.service.getLoans());

  getLoanTypes = async (_req: Request, res: Response) => res.json(await this.service.getLoanTypes());

  createLoan = async (req: Request, res: Response) => {
    const payload = {
      ...req.body,
      EmployeeID: req.user?.employeeId ?? req.body.EmployeeID
    };
    const result = await this.service.createLoan(payload);
    return res.status(201).json(result.recordset ?? { message: "Loan created" });
  };

  payLoanInstallment = async (req: Request, res: Response) => {
    const payload = {
      ...req.body,
      EmployeeID: req.user?.employeeId ?? req.body.EmployeeID
    };
    const result = await this.service.payLoanInstallment(payload);
    return res.json(result.recordset ?? { message: "Installment paid" });
  };
}
