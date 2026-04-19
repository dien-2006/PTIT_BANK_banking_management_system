USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 04_views.sql
-- Muc dich:
-- Tao cac view tong hop phuc vu man hinh nghiep vu va dashboard.
-- ============================================================

-- View tong hop khach hang va tai khoan
CREATE OR ALTER VIEW dbo.vw_CustomerAccountSummary
AS
SELECT
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    c.CustomerType,
    c.Phone,
    c.Email,
    c.[Status] AS CustomerStatus,
    COUNT(ba.AccountID) AS TotalAccounts,
    ISNULL(SUM(CASE WHEN ba.[Status] <> 'Closed' THEN ba.Balance ELSE 0 END), 0) AS TotalBalance
FROM dbo.CUSTOMER c
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON c.CustomerID = ba.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    c.CustomerType,
    c.Phone,
    c.Email,
    c.[Status];
GO

-- View chi tiet giao dich
CREATE OR ALTER VIEW dbo.vw_TransactionDetail
AS
SELECT
    bt.TransactionID,
    bt.TransactionCode,
    tt.TypeName AS TransactionTypeName,
    bt.SourceAccountID,
    src.AccountNumber AS SourceAccountNumber,
    bt.DestinationAccountID,
    dst.AccountNumber AS DestinationAccountNumber,
    bt.EmployeeID,
    e.FullName AS EmployeeName,
    bt.Channel,
    bt.Amount,
    bt.Fee,
    bt.TransactionDate,
    bt.[Description],
    bt.[Status]
FROM dbo.BANK_TRANSACTION bt
INNER JOIN dbo.TRANSACTION_TYPE tt
    ON bt.TransactionTypeID = tt.TransactionTypeID
LEFT JOIN dbo.BANK_ACCOUNT src
    ON bt.SourceAccountID = src.AccountID
LEFT JOIN dbo.BANK_ACCOUNT dst
    ON bt.DestinationAccountID = dst.AccountID
LEFT JOIN dbo.EMPLOYEE e
    ON bt.EmployeeID = e.EmployeeID;
GO

-- View tong hop tinh trang khoan vay
CREATE OR ALTER VIEW dbo.vw_LoanStatus
AS
SELECT
    l.LoanID,
    l.LoanCode,
    c.CustomerID,
    c.CustomerCode,
    c.FullName AS CustomerName,
    lt.LoanTypeName,
    l.PrincipalAmount,
    l.InterestRate,
    l.TermMonths,
    l.StartDate,
    l.EndDate,
    l.[Status],
    ISNULL(SUM(lp.AmountPaid), 0) AS TotalPaid,
    ISNULL(SUM(lp.PrincipalPaid), 0) AS TotalPrincipalPaid,
    ISNULL(SUM(lp.InterestPaid), 0) AS TotalInterestPaid,
    ISNULL(SUM(lp.PenaltyFee), 0) AS TotalPenaltyFee,
    l.PrincipalAmount - ISNULL(SUM(lp.PrincipalPaid), 0) AS RemainingPrincipal
FROM dbo.LOAN l
INNER JOIN dbo.CUSTOMER c
    ON l.CustomerID = c.CustomerID
INNER JOIN dbo.LOAN_TYPE lt
    ON l.LoanTypeID = lt.LoanTypeID
LEFT JOIN dbo.LOAN_PAYMENT lp
    ON l.LoanID = lp.LoanID
GROUP BY
    l.LoanID,
    l.LoanCode,
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    lt.LoanTypeName,
    l.PrincipalAmount,
    l.InterestRate,
    l.TermMonths,
    l.StartDate,
    l.EndDate,
    l.[Status];
GO

-- View tong hop hieu suat chi nhanh
CREATE OR ALTER VIEW dbo.vw_BranchPerformance
AS
SELECT
    b.BranchID,
    b.BranchCode,
    b.BranchName,
    COUNT(DISTINCT ba.AccountID) AS TotalAccounts,
    COUNT(DISTINCT ba.CustomerID) AS TotalCustomers,
    COUNT(DISTINCT bt.TransactionID) AS TotalTransactions,
    ISNULL(SUM(bt.Amount), 0) AS TotalTransactionAmount,
    ISNULL(SUM(bt.Fee), 0) AS TotalFeeRevenue
FROM dbo.BRANCH b
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON b.BranchID = ba.BranchID
LEFT JOIN dbo.BANK_TRANSACTION bt
    ON ba.AccountID = bt.SourceAccountID
    OR ba.AccountID = bt.DestinationAccountID
GROUP BY
    b.BranchID,
    b.BranchCode,
    b.BranchName;
GO

-- View cac khoan vay qua han
CREATE OR ALTER VIEW dbo.vw_OverdueLoans
AS
SELECT
    l.LoanID,
    l.LoanCode,
    c.CustomerCode,
    c.FullName AS CustomerName,
    b.BranchName,
    lt.LoanTypeName,
    l.PrincipalAmount,
    l.StartDate,
    l.EndDate,
    l.[Status],
    dbo.fn_GetLoanRemainingPrincipal(l.LoanID) AS RemainingPrincipal
FROM dbo.LOAN l
INNER JOIN dbo.CUSTOMER c
    ON l.CustomerID = c.CustomerID
INNER JOIN dbo.BRANCH b
    ON l.BranchID = b.BranchID
INNER JOIN dbo.LOAN_TYPE lt
    ON l.LoanTypeID = lt.LoanTypeID
WHERE l.[Status] = 'Overdue';
GO

-- View hieu suat lam viec cua nhan vien
CREATE OR ALTER VIEW dbo.vw_EmployeePerformance
AS
SELECT
    e.EmployeeID,
    e.FullName,
    b.BranchName,
    r.RoleName,
    COUNT(DISTINCT bt.TransactionID) AS TotalTransactionsHandled,
    ISNULL(SUM(bt.Amount), 0) AS TotalTransactionAmountHandled,
    COUNT(DISTINCT l.LoanID) AS TotalLoansHandled,
    COUNT(DISTINCT lp.LoanPaymentID) AS TotalLoanPaymentsHandled
FROM dbo.EMPLOYEE e
INNER JOIN dbo.BRANCH b
    ON e.BranchID = b.BranchID
INNER JOIN dbo.[ROLE] r
    ON e.RoleID = r.RoleID
LEFT JOIN dbo.BANK_TRANSACTION bt
    ON e.EmployeeID = bt.EmployeeID
LEFT JOIN dbo.LOAN l
    ON e.EmployeeID = l.EmployeeID
LEFT JOIN dbo.LOAN_PAYMENT lp
    ON e.EmployeeID = lp.EmployeeID
GROUP BY
    e.EmployeeID,
    e.FullName,
    b.BranchName,
    r.RoleName;
GO
