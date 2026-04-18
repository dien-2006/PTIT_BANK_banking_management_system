USE BankingManagementDB;
GO
-- Hàm tính tổng số dư của 1 khách hàng
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
    WHERE CustomerID = @CustomerID AND [Status] <> 'Closed';
    RETURN ISNULL(@TotalBalance, 0);
END;
GO
-- Hàm tính dư nợ gốc còn lại của khoản vay
CREATE OR ALTER FUNCTION dbo.fn_GetLoanRemainingPrincipal
(
    @LoanID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Principal DECIMAL(18,2);
    DECLARE @PaidPrincipal DECIMAL(18,2);
    SELECT @Principal = PrincipalAmount
    FROM dbo.LOAN
    WHERE LoanID = @LoanID;
    SELECT @PaidPrincipal = ISNULL(SUM(PrincipalPaid), 0)
    FROM dbo.LOAN_PAYMENT
    WHERE LoanID = @LoanID;
    RETURN ISNULL(@Principal, 0) - ISNULL(@PaidPrincipal, 0);
END;
GO
