--  Danh sách khách hàng và số lượng tài khoản họ sở hữu
SELECT
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    COUNT(ba.AccountID) AS TotalAccounts
FROM dbo.CUSTOMER c
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON c.CustomerID = ba.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerCode,
    c.FullName
ORDER BY TotalAccounts DESC, c.FullName;
GO
-- Tổng số dư của mỗi khách hàng
SELECT
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    ISNULL(SUM(CASE WHEN ba.[Status] <> 'Closed' THEN ba.Balance ELSE 0 END), 0) AS TotalBalance
FROM dbo.CUSTOMER c
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON c.CustomerID = ba.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerCode,
    c.FullName
ORDER BY TotalBalance DESC;
GO
-- Top 10 khách hàng có tổng số dư cao nhất
SELECT TOP 10
    c.CustomerID,
    c.CustomerCode,
    c.FullName,
    ISNULL(SUM(CASE WHEN ba.[Status] <> 'Closed' THEN ba.Balance ELSE 0 END), 0) AS TotalBalance
FROM dbo.CUSTOMER c
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON c.CustomerID = ba.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerCode,
    c.FullName
ORDER BY TotalBalance DESC;
GO
-- Thống kê số lượng giao dịch theo chi nhánh trong tháng hiện tại
SELECT
    b.BranchID,
    b.BranchCode,
    b.BranchName,
    COUNT(bt.TransactionID) AS TotalTransactions,
    ISNULL(SUM(bt.Amount), 0) AS TotalTransactionAmount
FROM dbo.BRANCH b
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON b.BranchID = ba.BranchID
LEFT JOIN dbo.BANK_TRANSACTION bt
    ON ba.AccountID = bt.SourceAccountID
    OR ba.AccountID = bt.DestinationAccountID
WHERE bt.TransactionDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
  AND bt.TransactionDate < DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
GROUP BY
    b.BranchID,
    b.BranchCode,
    b.BranchName
ORDER BY TotalTransactionAmount DESC;
GO
-- Tài khoản không phát sinh giao dịch trong 6 tháng gần nhất
SELECT
    ba.AccountID,
    ba.AccountNumber,
    c.FullName,
    ba.Balance,
    ba.[Status]
FROM dbo.BANK_ACCOUNT ba
INNER JOIN dbo.CUSTOMER c
    ON ba.CustomerID = c.CustomerID
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BANK_TRANSACTION bt
    WHERE bt.SourceAccountID = ba.AccountID
       OR bt.DestinationAccountID = ba.AccountID
      AND bt.TransactionDate >= DATEADD(MONTH, -6, GETDATE())
)
ORDER BY ba.AccountID;
GO
-- Liệt kê các khoản vay chưa thanh toán hết
SELECT
    l.LoanID,
    l.LoanCode,
    c.FullName AS CustomerName,
    lt.LoanTypeName,
    l.PrincipalAmount,
    dbo.fn_GetLoanRemainingPrincipal(l.LoanID) AS RemainingPrincipal,
    l.[Status]
FROM dbo.LOAN l
INNER JOIN dbo.CUSTOMER c
    ON l.CustomerID = c.CustomerID
INNER JOIN dbo.LOAN_TYPE lt
    ON l.LoanTypeID = lt.LoanTypeID
WHERE dbo.fn_GetLoanRemainingPrincipal(l.LoanID) > 0
ORDER BY RemainingPrincipal DESC;
GO
-- Tổng tiền vay theo từng loại khoản vay
SELECT
    lt.LoanTypeID,
    lt.LoanTypeName,
    COUNT(l.LoanID) AS TotalLoans,
    ISNULL(SUM(l.PrincipalAmount), 0) AS TotalPrincipalAmount
FROM dbo.LOAN_TYPE lt
LEFT JOIN dbo.LOAN l
    ON lt.LoanTypeID = l.LoanTypeID
GROUP BY
    lt.LoanTypeID,
    lt.LoanTypeName
ORDER BY TotalPrincipalAmount DESC;
GO
-- Nhân viên xử lý nhiều giao dịch nhất
SELECT TOP 10
    e.EmployeeID,
    e.FullName,
    b.BranchName,
    COUNT(bt.TransactionID) AS TotalTransactionsHandled,
    ISNULL(SUM(bt.Amount), 0) AS TotalAmountHandled
FROM dbo.EMPLOYEE e
INNER JOIN dbo.BRANCH b
    ON e.BranchID = b.BranchID
LEFT JOIN dbo.BANK_TRANSACTION bt
    ON e.EmployeeID = bt.EmployeeID
GROUP BY
    e.EmployeeID,
    e.FullName,
    b.BranchName
ORDER BY TotalTransactionsHandled DESC, TotalAmountHandled DESC;
GO
-- Lịch sử giao dịch chi tiết của một khách hàng theo khoảng thời gian
DECLARE @CustomerID INT = 1;
DECLARE @FromDate DATETIME = '2025-01-01';
DECLARE @ToDate   DATETIME = '2026-12-31';

SELECT
    c.CustomerCode,
    c.FullName,
    ba.AccountNumber,
    bt.TransactionCode,
    tt.TypeName AS TransactionTypeName,
    bt.Channel,
    bt.Amount,
    bt.Fee,
    bt.TransactionDate,
    bt.[Status],
    bt.[Description]
FROM dbo.CUSTOMER c
INNER JOIN dbo.BANK_ACCOUNT ba
    ON c.CustomerID = ba.CustomerID
INNER JOIN dbo.BANK_TRANSACTION bt
    ON ba.AccountID = bt.SourceAccountID
    OR ba.AccountID = bt.DestinationAccountID
INNER JOIN dbo.TRANSACTION_TYPE tt
    ON bt.TransactionTypeID = tt.TransactionTypeID
WHERE c.CustomerID = @CustomerID
  AND bt.TransactionDate >= @FromDate
  AND bt.TransactionDate <= @ToDate
ORDER BY bt.TransactionDate DESC;
GO
-- Doanh thu phí giao dịch theo tháng
SELECT
    YEAR(TransactionDate) AS [Year],
    MONTH(TransactionDate) AS [Month],
    COUNT(TransactionID) AS TotalTransactions,
    ISNULL(SUM(Fee), 0) AS TotalFeeRevenue
FROM dbo.BANK_TRANSACTION
WHERE [Status] = 'Success'
GROUP BY
    YEAR(TransactionDate),
    MONTH(TransactionDate)
ORDER BY [Year], [Month];
GO
-- Tỷ lệ giao dịch theo kênh
SELECT
    Channel,
    COUNT(TransactionID) AS TotalTransactions,
    ISNULL(SUM(Amount), 0) AS TotalAmount
FROM dbo.BANK_TRANSACTION
GROUP BY Channel
ORDER BY TotalTransactions DESC;
GO
-- Top chi nhánh có doanh số giao dịch lớn nhất
SELECT TOP 10
    b.BranchID,
    b.BranchCode,
    b.BranchName,
    COUNT(bt.TransactionID) AS TotalTransactions,
    ISNULL(SUM(bt.Amount), 0) AS TotalTransactionAmount
FROM dbo.BRANCH b
LEFT JOIN dbo.BANK_ACCOUNT ba
    ON b.BranchID = ba.BranchID
LEFT JOIN dbo.BANK_TRANSACTION bt
    ON ba.AccountID = bt.SourceAccountID
    OR ba.AccountID = bt.DestinationAccountID
GROUP BY
    b.BranchID,
    b.BranchCode,
    b.BranchName
ORDER BY TotalTransactionAmount DESC;
GO
-- Chỉ số tổng quan
SELECT
    (SELECT COUNT(*) FROM dbo.CUSTOMER) AS TotalCustomers,
    (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT) AS TotalAccounts,
    (SELECT COUNT(*) FROM dbo.BANK_TRANSACTION WHERE CAST(TransactionDate AS DATE) = CAST(GETDATE() AS DATE)) AS TodayTransactions,
    (SELECT ISNULL(SUM(Balance), 0) FROM dbo.BANK_ACCOUNT WHERE [Status] <> 'Closed') AS TotalSystemBalance,
    (SELECT COUNT(*) FROM dbo.LOAN WHERE [Status] = 'Overdue') AS OverdueLoans,
    (SELECT COUNT(*) FROM dbo.BANK_ACCOUNT WHERE [Status] = 'Blocked') AS BlockedAccounts;
GO
-- Khách hàng mới theo tháng
SELECT
    YEAR(CreatedDate) AS [Year],
    MONTH(CreatedDate) AS [Month],
    COUNT(CustomerID) AS NewCustomers
FROM dbo.CUSTOMER
GROUP BY
    YEAR(CreatedDate),
    MONTH(CreatedDate)
ORDER BY [Year], [Month];
GO
-- Giao dịch theo tháng
SELECT
    YEAR(TransactionDate) AS [Year],
    MONTH(TransactionDate) AS [Month],
    COUNT(TransactionID) AS TotalTransactions,
    ISNULL(SUM(Amount), 0) AS TotalAmount
FROM dbo.BANK_TRANSACTION
GROUP BY
    YEAR(TransactionDate),
    MONTH(TransactionDate)
ORDER BY [Year], [Month];
GO