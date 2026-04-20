import { z } from "zod";
import { SqlRepository } from "./sql-repository.js";

function normalizeGender(value: string) {
  const normalized = value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  if (["male", "nam"].includes(normalized)) {
    return "Male";
  }

  if (["female", "nu"].includes(normalized)) {
    return "Female";
  }

  if (["other", "khac"].includes(normalized)) {
    return "Other";
  }

  return value.trim();
}

const customerInputSchema = z
  .object({
    FullName: z.string().min(1),
    Gender: z.string().min(1),
    DateOfBirth: z.string().min(1),
    NationalID: z.string().optional(),
    IdentityNumber: z.string().optional(),
    Phone: z.string().optional(),
    PhoneNumber: z.string().optional(),
    Email: z.string().email().nullable().optional().or(z.literal("")),
    Address: z.string().min(1),
    Occupation: z.string().optional(),
    CustomerType: z.string().default("Individual")
  })
  .transform((data) => ({
    FullName: data.FullName,
    Gender: normalizeGender(data.Gender),
    DateOfBirth: data.DateOfBirth,
    NationalID: data.NationalID ?? data.IdentityNumber ?? "",
    Phone: data.Phone ?? data.PhoneNumber ?? "",
    Email: data.Email || null,
    Address: data.Address,
    Occupation: data.Occupation ?? null,
    CustomerType: data.CustomerType
  }));

const openAccountSchema = z
  .object({
    CustomerID: z.coerce.number().int().positive(),
    BranchID: z.coerce.number().int().positive(),
    AccountTypeID: z.coerce.number().int().positive(),
    Currency: z.string().default("VND"),
    InitialBalance: z.coerce.number().nonnegative().optional(),
    InitialDeposit: z.coerce.number().nonnegative().optional()
  })
  .transform((data) => ({
    CustomerID: data.CustomerID,
    BranchID: data.BranchID,
    AccountTypeID: data.AccountTypeID,
    Currency: data.Currency,
    InitialBalance: data.InitialBalance ?? data.InitialDeposit ?? 0
  }));

const statusUpdateSchema = z
  .object({
    AccountID: z.coerce.number().int().positive(),
    NewStatus: z.string().optional(),
    Status: z.string().optional(),
    ChangedByType: z.string().optional(),
    EmployeeID: z.coerce.number().int().positive().optional(),
    Reason: z.string().optional()
  })
  .transform((data) => ({
    AccountID: data.AccountID,
    NewStatus: data.NewStatus ?? data.Status ?? "",
    ChangedByType: data.ChangedByType ?? "Employee",
    EmployeeID: data.EmployeeID ?? null,
    Reason: data.Reason ?? null
  }));

const issueCardSchema = z.object({
  AccountID: z.union([z.string(), z.number()]),
  ExpiryDate: z.string().min(1),
  CardType: z.string().min(1),
  PINHash: z.string().min(1)
});

const loanSchema = z.object({
  CustomerID: z.coerce.number().int().positive(),
  BranchID: z.coerce.number().int().positive(),
  EmployeeID: z.coerce.number().int().positive(),
  LoanTypeID: z.coerce.number().int().positive(),
  PrincipalAmount: z.coerce.number().positive(),
  InterestRate: z.coerce.number().nonnegative(),
  TermMonths: z.coerce.number().int().positive(),
  StartDate: z.string().min(1),
  EndDate: z.string().min(1)
});

const loanPaymentSchema = z.object({
  LoanID: z.coerce.number().int().positive(),
  PrincipalPaid: z.coerce.number().nonnegative(),
  InterestPaid: z.coerce.number().nonnegative(),
  PenaltyFee: z.coerce.number().nonnegative().default(0),
  PaymentChannel: z.string().min(1),
  EmployeeID: z.coerce.number().int().positive().optional(),
  Note: z.string().optional()
});

const registerOnlineSchema = z
  .object({
    CustomerID: z.coerce.number().int().positive(),
    Username: z.string().min(3),
    PasswordHash: z.string().optional(),
    Password: z.string().optional()
  })
  .transform((data) => ({
    CustomerID: data.CustomerID,
    Username: data.Username,
    PasswordHash: data.PasswordHash ?? data.Password ?? ""
  }));

const historySchema = z
  .object({
    AccountID: z.coerce.number().int().positive().optional(),
    FromDate: z.string().optional(),
    ToDate: z.string().optional()
  })
  .transform((data) => ({
    AccountID: data.AccountID ?? null,
    FromDate: data.FromDate || null,
    ToDate: data.ToDate || null
  }));

const moneySchema = z
  .object({
    DestinationAccountID: z.union([z.string(), z.number()]).optional(),
    SourceAccountID: z.union([z.string(), z.number()]).optional(),
    AccountID: z.union([z.string(), z.number()]).optional(),
    Amount: z.coerce.number().positive(),
    EmployeeID: z.coerce.number().int().positive().optional(),
    PerformedBy: z.coerce.number().int().positive().optional(),
    Channel: z.string().optional(),
    Fee: z.coerce.number().nonnegative().optional(),
    Description: z.string().optional()
  });

const transferSchema = z
  .object({
    SourceAccountID: z.union([z.string(), z.number()]).optional(),
    DestinationAccountID: z.union([z.string(), z.number()]).optional(),
    FromAccountID: z.union([z.string(), z.number()]).optional(),
    ToAccountID: z.union([z.string(), z.number()]).optional(),
    Amount: z.coerce.number().positive(),
    Fee: z.coerce.number().nonnegative().optional(),
    EmployeeID: z.coerce.number().int().positive().optional(),
    PerformedBy: z.coerce.number().int().positive().optional(),
    Channel: z.string().optional(),
    Description: z.string().optional()
  })
  .transform((data) => ({
    SourceAccountID: data.SourceAccountID ?? data.FromAccountID ?? null,
    DestinationAccountID: data.DestinationAccountID ?? data.ToAccountID ?? null,
    Amount: data.Amount,
    Fee: data.Fee ?? 0,
    EmployeeID: data.EmployeeID ?? data.PerformedBy ?? null,
    Channel: data.Channel ?? "Counter",
    Description: data.Description ?? null
  }));

export class BankingRepository extends SqlRepository {
  private normalizeAccountIdentifier(value: string | number | null | undefined) {
    if (value == null) {
      return null;
    }

    const normalized = String(value).trim();
    return normalized ? normalized : null;
  }

  private async resolveAccountId(accountIdentifier: string | number | null | undefined) {
    const normalized = this.normalizeAccountIdentifier(accountIdentifier);
    if (!normalized) {
      return null;
    }

    const numericValue = Number(normalized);
    const rows = await this.executeQuery<{ AccountID: number }>(
      `
      SELECT TOP 1 AccountID
      FROM dbo.BANK_ACCOUNT
      WHERE AccountNumber = @AccountNumber
         OR AccountID = TRY_CONVERT(INT, @AccountNumber)
      ORDER BY CASE WHEN AccountNumber = @AccountNumber THEN 0 ELSE 1 END, AccountID
      `,
      [{ name: "AccountNumber", value: normalized }]
    );

    const resolvedAccountId = rows[0]?.AccountID;

    if (resolvedAccountId) {
      return resolvedAccountId;
    }

    if (Number.isInteger(numericValue) && numericValue > 0 && numericValue <= 2147483647) {
      return numericValue;
    }

    throw new Error(`Không tìm thấy tài khoản ${normalized}`);
  }

  async getDashboardOverview() {
    return this.executeQuery(
      `
      SELECT
        (SELECT COUNT(*) FROM dbo.CUSTOMER) AS totalCustomers,
        (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT) AS totalAccounts,
        (SELECT COUNT(*) FROM dbo.BANK_TRANSACTION WHERE CAST(TransactionDate AS DATE) = CAST(GETDATE() AS DATE)) AS transactionsToday,
        (SELECT ISNULL(SUM(Balance), 0) FROM dbo.BANK_ACCOUNT WHERE [Status] <> 'Closed') AS totalBalance,
        (SELECT COUNT(*) FROM dbo.LOAN WHERE [Status] = 'Overdue') AS overdueLoans,
        (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT WHERE [Status] = 'Blocked') AS blockedAccounts
      `
    );
  }

  async getTopCustomers() {
    return this.executeQuery(
      `
      SELECT TOP 5
        c.CustomerID,
        c.CustomerCode,
        c.FullName,
        dbo.fn_GetCustomerTotalBalance(c.CustomerID) AS TotalBalance
      FROM dbo.CUSTOMER c
      ORDER BY dbo.fn_GetCustomerTotalBalance(c.CustomerID) DESC
      `
    );
  }

  async getTopBranches() {
    return this.executeQuery("SELECT TOP 5 BranchID, BranchCode, BranchName, TotalAccounts, TotalTransactions FROM dbo.vw_BranchPerformance ORDER BY TotalTransactionAmount DESC");
  }

  async getCustomers() {
    return this.executeQuery("SELECT CustomerID, CustomerCode, FullName, Phone AS PhoneNumber, Email, CustomerType, CustomerStatus, TotalAccounts, TotalBalance FROM dbo.vw_CustomerAccountSummary ORDER BY CustomerID DESC");
  }

  async addCustomer(payload: unknown) {
    const data = customerInputSchema.parse(payload);
    return this.executeProcedure("sp_AddCustomer", Object.entries(data).map(([name, value]) => ({ name, value })));
  }

  async registerOnlineAccount(payload: unknown) {
    const data = registerOnlineSchema.parse(payload);
    return this.executeProcedure(
      "sp_RegisterCustomerOnlineAccount",
      Object.entries(data).map(([name, value]) => ({ name, value }))
    );
  }

  async getBranches() {
    return this.executeQuery("SELECT BranchID, BranchCode, BranchName, Address FROM dbo.BRANCH ORDER BY BranchName");
  }

  async getAccountTypes() {
    return this.executeQuery("SELECT AccountTypeID, TypeName AS AccountTypeName, MinBalance FROM dbo.ACCOUNT_TYPE ORDER BY TypeName");
  }

  async getAccounts() {
    return this.executeQuery(
      `
      SELECT
        a.AccountID,
        a.AccountNumber,
        a.CustomerID,
        c.FullName,
        a.AccountTypeID,
        t.TypeName AS AccountTypeName,
        a.BranchID,
        b.BranchName,
        a.Balance,
        a.[Status] AS Status,
        a.Currency
      FROM dbo.BANK_ACCOUNT a
      INNER JOIN dbo.CUSTOMER c ON c.CustomerID = a.CustomerID
      INNER JOIN dbo.ACCOUNT_TYPE t ON t.AccountTypeID = a.AccountTypeID
      INNER JOIN dbo.BRANCH b ON b.BranchID = a.BranchID
      ORDER BY a.AccountID DESC
      `
    );
  }

  async openAccount(payload: unknown) {
    const data = openAccountSchema.parse(payload);
    return this.executeProcedure("sp_OpenBankAccount", Object.entries(data).map(([name, value]) => ({ name, value })));
  }

  async updateAccountStatus(payload: unknown) {
    const data = statusUpdateSchema.parse(payload);
    return this.executeProcedure(
      "sp_UpdateBankAccountStatus",
      Object.entries(data).map(([name, value]) => ({ name, value: value ?? null }))
    );
  }

  async deposit(payload: unknown) {
    const data = moneySchema.parse(payload);
    const destinationAccountId = await this.resolveAccountId(data.DestinationAccountID ?? data.AccountID ?? null);

    return this.executeProcedure("sp_DepositMoney", [
      { name: "DestinationAccountID", value: destinationAccountId },
      { name: "Amount", value: data.Amount },
      { name: "EmployeeID", value: data.EmployeeID ?? data.PerformedBy ?? null },
      { name: "Channel", value: data.Channel ?? "Counter" },
      { name: "Description", value: data.Description ?? null }
    ]);
  }

  async withdraw(payload: unknown) {
    const data = moneySchema.parse(payload);
    const sourceAccountId = await this.resolveAccountId(data.SourceAccountID ?? data.AccountID ?? null);

    return this.executeProcedure("sp_WithdrawMoney", [
      { name: "SourceAccountID", value: sourceAccountId },
      { name: "Amount", value: data.Amount },
      { name: "Fee", value: data.Fee ?? 0 },
      { name: "EmployeeID", value: data.EmployeeID ?? data.PerformedBy ?? null },
      { name: "Channel", value: data.Channel ?? "Counter" },
      { name: "Description", value: data.Description ?? null }
    ]);
  }

  async transfer(payload: unknown) {
    const data = transferSchema.parse(payload);
    const sourceAccountId = await this.resolveAccountId(data.SourceAccountID);
    const destinationAccountId = await this.resolveAccountId(data.DestinationAccountID);

    return this.executeProcedure(
      "sp_TransferMoney",
      [
        { name: "SourceAccountID", value: sourceAccountId },
        { name: "DestinationAccountID", value: destinationAccountId },
        { name: "Amount", value: data.Amount },
        { name: "Fee", value: data.Fee ?? 0 },
        { name: "EmployeeID", value: data.EmployeeID ?? null },
        { name: "Channel", value: data.Channel ?? "Counter" },
        { name: "Description", value: data.Description ?? null }
      ]
    );
  }

  async getTransactionHistory(payload: unknown) {
    const data = historySchema.parse(payload);

    if (!data.AccountID) {
      const filterClauses: string[] = [];
      const inputs: Array<{ name: string; value: string }> = [];

      if (data.FromDate) {
        filterClauses.push("CAST(TransactionDate AS DATE) >= CAST(@FromDate AS DATE)");
        inputs.push({ name: "FromDate", value: data.FromDate });
      }

      if (data.ToDate) {
        filterClauses.push("CAST(TransactionDate AS DATE) <= CAST(@ToDate AS DATE)");
        inputs.push({ name: "ToDate", value: data.ToDate });
      }

      const whereClause = filterClauses.length ? `WHERE ${filterClauses.join(" AND ")}` : "";

      return {
        recordset: await this.executeQuery(
          `
          SELECT
            TransactionID,
            TransactionCode,
            TransactionTypeName,
            SourceAccountID,
            SourceAccountNumber,
            DestinationAccountID,
            DestinationAccountNumber,
            Channel,
            Amount,
            Fee,
            TransactionDate,
            [Description],
            [Status]
          FROM dbo.vw_TransactionDetail
          ${whereClause}
          ORDER BY TransactionDate DESC, TransactionID DESC
          `
          ,
          inputs
        )
      };
    }

    return this.executeProcedure(
      "sp_GetTransactionHistory",
      [
        { name: "AccountID", value: data.AccountID },
        { name: "FromDate", value: data.FromDate },
        { name: "ToDate", value: data.ToDate }
      ]
    );
  }

  async getCards() {
    return this.executeQuery(
      `
      SELECT
        c.CardID,
        c.AccountID,
        a.AccountNumber,
        c.CardNumber,
        c.CardType,
        c.[Status] AS Status,
        c.ExpiryDate
      FROM dbo.CARD c
      INNER JOIN dbo.BANK_ACCOUNT a ON a.AccountID = c.AccountID
      ORDER BY CardID DESC
      `
    );
  }

  async issueCard(payload: unknown) {
    const data = issueCardSchema.parse(payload);
    const accountId = await this.resolveAccountId(data.AccountID);

    return this.executeProcedure("sp_IssueCard", [
      { name: "AccountID", value: accountId },
      { name: "ExpiryDate", value: data.ExpiryDate },
      { name: "CardType", value: data.CardType },
      { name: "PINHash", value: data.PINHash }
    ]);
  }

  async getLoans() {
    return this.executeQuery("SELECT LoanID, LoanCode, CustomerID, CustomerName AS FullName, LoanTypeName, PrincipalAmount, InterestRate, TermMonths, StartDate, EndDate, [Status] AS Status, RemainingPrincipal FROM dbo.vw_LoanStatus ORDER BY LoanID DESC");
  }

  async getLoanTypes() {
    return this.executeQuery("SELECT LoanTypeID, LoanTypeName FROM LOAN_TYPE ORDER BY LoanTypeName");
  }

  async createLoan(payload: unknown) {
    const data = loanSchema.parse(payload);
    return this.executeProcedure("sp_CreateLoan", Object.entries(data).map(([name, value]) => ({ name, value })));
  }

  async payLoanInstallment(payload: unknown) {
    const data = loanPaymentSchema.parse(payload);
    return this.executeProcedure(
      "sp_PayLoanInstallment",
      Object.entries(data).map(([name, value]) => ({ name, value: value ?? null }))
    );
  }
}
