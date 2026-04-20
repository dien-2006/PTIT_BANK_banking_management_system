USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 01_functions.sql
-- Muc dich:
-- Khai bao cac ham tinh toan duoc tai su dung trong view/procedure.
-- ============================================================

-- Ham tinh tong so du cua tat ca tai khoan con hoat dong cua 1 khach hang
CREATE OR ALTER FUNCTION dbo.fn_GetCustomerTotalBalance
(
    @CustomerID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalBalance DECIMAL(18,2);

    SELECT @TotalBalance = ISNULL(SUM(Balance), 0)
    FROM dbo.BANK_ACCOUNT
    WHERE CustomerID = @CustomerID
      AND [Status] <> 'Closed';

    RETURN ISNULL(@TotalBalance, 0);
END;
GO

-- Ham tinh du no goc con lai cua 1 khoan vay
CREATE OR ALTER FUNCTION dbo.fn_GetLoanRemainingPrincipal
(
    @LoanID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @PrincipalAmount DECIMAL(18,2);
    DECLARE @PrincipalPaid DECIMAL(18,2);

    SELECT @PrincipalAmount = PrincipalAmount
    FROM dbo.LOAN
    WHERE LoanID = @LoanID;

    SELECT @PrincipalPaid = ISNULL(SUM(PrincipalPaid), 0)
    FROM dbo.LOAN_PAYMENT
    WHERE LoanID = @LoanID;

    RETURN ISNULL(@PrincipalAmount, 0) - ISNULL(@PrincipalPaid, 0);
END;
GO
