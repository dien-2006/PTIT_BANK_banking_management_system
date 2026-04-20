USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 05_query_and_dashboard_procedures.sql
-- Muc dich:
-- Chua cac procedure doc du lieu cho danh sach nghiep vu, dashboard, bao cao.
-- Khong thay doi du lieu, chu yeu SELECT tong hop.
-- ============================================================

-- KPI tong quan cho dashboard
CREATE OR ALTER PROCEDURE dbo.sp_GetDashboardOverview
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*) FROM dbo.CUSTOMER) AS TotalCustomers,
        (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT) AS TotalAccounts,
        (SELECT COUNT(*) FROM dbo.BANK_TRANSACTION WHERE CAST(TransactionDate AS DATE) = CAST(GETDATE() AS DATE)) AS TodayTransactions,
        (SELECT ISNULL(SUM(Balance), 0) FROM dbo.BANK_ACCOUNT WHERE [Status] <> 'Closed') AS TotalSystemBalance,
        (SELECT COUNT(*) FROM dbo.LOAN WHERE [Status] = 'Overdue') AS OverdueLoans,
        (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT WHERE [Status] = 'Blocked') AS BlockedAccounts;
END;
GO

-- Lay top khach hang co tong so du cao nhat
CREATE OR ALTER PROCEDURE dbo.sp_GetTopCustomers
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        c.CustomerID,
        c.CustomerCode,
        c.FullName,
        dbo.fn_GetCustomerTotalBalance(c.CustomerID) AS TotalBalance
    FROM dbo.CUSTOMER c
    ORDER BY dbo.fn_GetCustomerTotalBalance(c.CustomerID) DESC, c.CustomerID DESC;
END;
GO

-- Lay top chi nhanh co doanh so giao dich cao nhat
CREATE OR ALTER PROCEDURE dbo.sp_GetTopBranches
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        BranchID,
        BranchCode,
        BranchName,
        TotalAccounts,
        TotalCustomers,
        TotalTransactions,
        TotalTransactionAmount,
        TotalFeeRevenue
    FROM dbo.vw_BranchPerformance
    ORDER BY TotalTransactionAmount DESC, BranchID DESC;
END;
GO

-- Lay danh sach tong hop khach hang
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CustomerID,
        CustomerCode,
        FullName,
        Phone,
        Email,
        CustomerType,
        CustomerStatus,
        TotalAccounts,
        TotalBalance
    FROM dbo.vw_CustomerAccountSummary
    ORDER BY CustomerID DESC;
END;
GO

-- Lay danh sach tong hop tai khoan ngan hang
CREATE OR ALTER PROCEDURE dbo.sp_GetAccountSummary
AS
BEGIN
    SET NOCOUNT ON;

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
        a.[Status],
        a.Currency,
        a.OpenDate
    FROM dbo.BANK_ACCOUNT a
    INNER JOIN dbo.CUSTOMER c
        ON c.CustomerID = a.CustomerID
    INNER JOIN dbo.ACCOUNT_TYPE t
        ON t.AccountTypeID = a.AccountTypeID
    INNER JOIN dbo.BRANCH b
        ON b.BranchID = a.BranchID
    ORDER BY a.AccountID DESC;
END;
GO

-- Lay danh sach the ngan hang
CREATE OR ALTER PROCEDURE dbo.sp_GetCardSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CardID,
        AccountID,
        CardNumber,
        CardType,
        [Status],
        IssueDate,
        ExpiryDate
    FROM dbo.CARD
    ORDER BY CardID DESC;
END;
GO

-- Lay danh sach tong hop khoan vay
CREATE OR ALTER PROCEDURE dbo.sp_GetLoanSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LoanID,
        LoanCode,
        CustomerID,
        CustomerCode,
        CustomerName,
        AccountID,
        AccountNumber,
        LoanTypeName,
        PrincipalAmount,
        InterestRate,
        TermMonths,
        StartDate,
        EndDate,
        [Status],
        TotalPaid,
        RemainingPrincipal
    FROM dbo.vw_LoanStatus
    ORDER BY LoanID DESC;
END;
GO

-- Lay danh sach chi nhanh de do vao combobox / bo loc
CREATE OR ALTER PROCEDURE dbo.sp_GetBranches
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        BranchID,
        BranchCode,
        BranchName,
        [Address],
        City,
        Phone,
        OpenDate,
        [Status]
    FROM dbo.BRANCH
    ORDER BY BranchName;
END;
GO

-- Lay danh sach loai tai khoan
CREATE OR ALTER PROCEDURE dbo.sp_GetAccountTypes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        AccountTypeID,
        TypeName AS AccountTypeName,
        MinBalance,
        InterestRate,
        [Description]
    FROM dbo.ACCOUNT_TYPE
    ORDER BY TypeName;
END;
GO

-- Lay danh sach loai khoan vay
CREATE OR ALTER PROCEDURE dbo.sp_GetLoanTypes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LoanTypeID,
        LoanTypeName,
        MaxAmount,
        DefaultInterestRate,
        MaxTermMonths,
        [Description]
    FROM dbo.LOAN_TYPE
    ORDER BY LoanTypeName;
END;
GO

-- Dashboard: so luong giao dich theo thang
CREATE OR ALTER PROCEDURE dbo.sp_GetMonthlyTransactionCount
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        YEAR(TransactionDate) AS [Year],
        MONTH(TransactionDate) AS [Month],
        COUNT(TransactionID) AS TotalTransactions
    FROM dbo.vw_TransactionDetail
    GROUP BY YEAR(TransactionDate), MONTH(TransactionDate)
    ORDER BY [Year], [Month];
END;
GO

-- Dashboard: tong gia tri giao dich theo thang
CREATE OR ALTER PROCEDURE dbo.sp_GetMonthlyTransactionAmount
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        YEAR(TransactionDate) AS [Year],
        MONTH(TransactionDate) AS [Month],
        ISNULL(SUM(Amount), 0) AS TotalAmount
    FROM dbo.vw_TransactionDetail
    GROUP BY YEAR(TransactionDate), MONTH(TransactionDate)
    ORDER BY [Year], [Month];
END;
GO

-- Dashboard: co cau giao dich theo loai
CREATE OR ALTER PROCEDURE dbo.sp_GetTransactionTypeBreakdown
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TransactionTypeName,
        COUNT(TransactionID) AS TotalTransactions,
        ISNULL(SUM(Amount), 0) AS TotalAmount
    FROM dbo.vw_TransactionDetail
    GROUP BY TransactionTypeName
    ORDER BY TotalTransactions DESC, TotalAmount DESC;
END;
GO

-- Dashboard: co cau giao dich theo kenh
CREATE OR ALTER PROCEDURE dbo.sp_GetTransactionChannelBreakdown
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Channel,
        COUNT(TransactionID) AS TotalTransactions,
        ISNULL(SUM(Amount), 0) AS TotalAmount
    FROM dbo.vw_TransactionDetail
    GROUP BY Channel
    ORDER BY TotalTransactions DESC, TotalAmount DESC;
END;
GO

-- Dashboard: du no con lai theo loai khoan vay
CREATE OR ALTER PROCEDURE dbo.sp_GetLoanOutstandingByType
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LoanTypeName,
        COUNT(LoanID) AS TotalLoans,
        ISNULL(SUM(RemainingPrincipal), 0) AS TotalRemainingPrincipal
    FROM dbo.vw_LoanStatus
    GROUP BY LoanTypeName
    ORDER BY TotalRemainingPrincipal DESC, TotalLoans DESC;
END;
GO

-- Bao cao: danh sach khoan vay qua han
CREATE OR ALTER PROCEDURE dbo.sp_GetOverdueLoanSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.vw_OverdueLoans
    ORDER BY EndDate, LoanID;
END;
GO

-- Bao cao: hieu suat nhan vien
CREATE OR ALTER PROCEDURE dbo.sp_GetEmployeePerformance
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.vw_EmployeePerformance
    ORDER BY TotalTransactionsHandled DESC, TotalTransactionAmountHandled DESC, EmployeeID DESC;
END;
GO
