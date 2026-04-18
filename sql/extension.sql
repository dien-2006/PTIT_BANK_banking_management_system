-- TRIGGER TỰ KHÓA THẺ KHI TÀI KHOẢN BỊ KHÓA / ĐÓNG
CREATE OR ALTER TRIGGER dbo.trg_BankAccount_BlockCard
ON dbo.BANK_ACCOUNT
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE([Status])
        RETURN;
    UPDATE c
    SET c.[Status] =
        CASE
            WHEN i.[Status] = 'Blocked' THEN 'Blocked'
            WHEN i.[Status] = 'Closed'  THEN 'Cancelled'
            ELSE c.[Status]
        END
    FROM dbo.CARD c
    INNER JOIN inserted i
        ON c.AccountID = i.AccountID
    INNER JOIN deleted d
        ON i.AccountID = d.AccountID
    WHERE d.[Status] <> i.[Status]
      AND i.[Status] IN ('Blocked', 'Closed')
      AND c.[Status] IN ('Active', 'Blocked');
END;
GO
/*
TRIGGER TỰ ĐỔI TRẠNG THÁI KHOẢN VAY THÀNH OVERDUE
Vì SQL Server không tự chạy theo ngày nếu không có job, nên cách hợp lý trong bài tập lớn là viết procedure cập nhật overdue, rồi gọi định kỳ hoặc trước khi lên báo cáo
*/
-- Procedure cập nhật khoản vay quá hạn
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOverdueLoans
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE l
    SET l.[Status] = 'Overdue'
    FROM dbo.LOAN l
    WHERE l.[Status] IN ('Approved', 'Paying')
      AND l.EndDate < CAST(GETDATE() AS DATE)
      AND dbo.fn_GetLoanRemainingPrincipal(l.LoanID) > 0;
    SELECT
        LoanID,
        LoanCode,
        CustomerID,
        EndDate,
        [Status],
        dbo.fn_GetLoanRemainingPrincipal(LoanID) AS RemainingPrincipal
    FROM dbo.LOAN
    WHERE [Status] = 'Overdue'
    ORDER BY EndDate;
END;
GO
-- View khoản vay quá hạn
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
-- VIEW HIỆU SUẤT NHÂN VIÊN
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
-- 