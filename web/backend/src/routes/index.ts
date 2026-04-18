import { Router } from "express";
import { AuthController } from "../controllers/auth-controller.js";
import { BankingController } from "../controllers/banking-controller.js";
import { requireAuth, requireRoles } from "../middleware/auth.js";
import { AuthRepository } from "../repositories/auth-repository.js";
import { BankingRepository } from "../repositories/banking-repository.js";
import { AuthService } from "../services/auth-service.js";
import { BankingService } from "../services/banking-service.js";
import { asyncHandler } from "../utils/async-handler.js";

const router = Router();

const authController = new AuthController(new AuthService(new AuthRepository()));
const bankingController = new BankingController(new BankingService(new BankingRepository()));

router.get("/health", (_req, res) => res.json({ status: "ok" }));

router.post("/api/auth/login", asyncHandler(authController.systemLogin));
router.post("/api/customers/online-login", asyncHandler(authController.customerOnlineLogin));

router.use("/api", requireAuth);

router.get("/api/dashboard", requireRoles("Admin", "Branch Manager"), asyncHandler(bankingController.getDashboard));
router.get("/api/customers", requireRoles("Admin", "Teller"), asyncHandler(bankingController.getCustomers));
router.post("/api/customers", requireRoles("Admin", "Teller"), asyncHandler(bankingController.addCustomer));
router.post(
  "/api/customers/register-online",
  requireRoles("Admin", "Teller"),
  asyncHandler(bankingController.registerOnlineAccount)
);
router.get("/api/branches", requireRoles("Admin", "Teller", "Loan Officer", "Branch Manager"), asyncHandler(bankingController.getBranches));
router.get(
  "/api/account-types",
  requireRoles("Admin", "Teller", "Loan Officer", "Branch Manager"),
  asyncHandler(bankingController.getAccountTypes)
);
router.get("/api/accounts", requireRoles("Admin", "Teller"), asyncHandler(bankingController.getAccounts));
router.post("/api/accounts/open", requireRoles("Admin", "Teller"), asyncHandler(bankingController.openAccount));
router.patch("/api/accounts/status", requireRoles("Admin", "Teller"), asyncHandler(bankingController.updateAccountStatus));
router.post("/api/transactions/deposit", requireRoles("Admin", "Teller"), asyncHandler(bankingController.deposit));
router.post("/api/transactions/withdraw", requireRoles("Admin", "Teller"), asyncHandler(bankingController.withdraw));
router.post("/api/transactions/transfer", requireRoles("Admin", "Teller"), asyncHandler(bankingController.transfer));
router.get(
  "/api/transactions/history",
  requireRoles("Admin", "Teller", "Branch Manager"),
  asyncHandler(bankingController.getTransactionHistory)
);
router.get("/api/cards", requireRoles("Admin", "Teller"), asyncHandler(bankingController.getCards));
router.post("/api/cards/issue", requireRoles("Admin", "Teller"), asyncHandler(bankingController.issueCard));
router.get("/api/loans", requireRoles("Admin", "Loan Officer"), asyncHandler(bankingController.getLoans));
router.get("/api/loan-types", requireRoles("Admin", "Loan Officer"), asyncHandler(bankingController.getLoanTypes));
router.post("/api/loans", requireRoles("Admin", "Loan Officer"), asyncHandler(bankingController.createLoan));
router.post("/api/loans/payment", requireRoles("Admin", "Loan Officer"), asyncHandler(bankingController.payLoanInstallment));

export { router };
