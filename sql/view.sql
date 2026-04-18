USE BankingManagementDB;
GO
-- View tổng hợp khách hàng - tài khoản
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
-- View chi tiết giao dịch
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
-- View tình trạng khoản vay
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
-- View hiệu suất chi nhánh
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
-- 
