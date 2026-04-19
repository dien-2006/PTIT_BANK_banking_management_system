USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 02_procedures.sql
-- Muc dich:
-- Chua toan bo stored procedure nghiep vu chinh cua he thong.
-- Nhom chuc nang:
-- 1. Khach hang
-- 2. Tai khoan ngan hang
-- 3. Giao dich
-- 4. Tai khoan online
-- 5. The ngan hang
-- 6. Khoan vay
-- 7. He thong dang nhap
-- ============================================================

-- ============================================================
-- NHOM 1: KHACH HANG
-- Them moi khach hang
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_AddCustomer
    @FullName        NVARCHAR(100),
    @Gender          VARCHAR(10),
    @DateOfBirth     DATE,
    @NationalID      VARCHAR(20),
    @Phone           VARCHAR(15),
    @Email           VARCHAR(100) = NULL,
    @Address         NVARCHAR(255),
    @Occupation      NVARCHAR(100) = NULL,
    @CustomerType    VARCHAR(20) = 'Individual'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewCode VARCHAR(20);

    IF NULLIF(LTRIM(RTRIM(@NationalID)), '') IS NULL
    BEGIN
        RAISERROR(N'NationalID khong duoc de trong.', 16, 1);
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(@Phone)), '') IS NULL
    BEGIN
        RAISERROR(N'So dien thoai khong duoc de trong.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE NationalID = @NationalID)
    BEGIN
        RAISERROR(N'NationalID da ton tai.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE Phone = @Phone)
    BEGIN
        RAISERROR(N'So dien thoai da ton tai.', 16, 1);
        RETURN;
    END

    IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE Email = @Email)
    BEGIN
        RAISERROR(N'Email da ton tai.', 16, 1);
        RETURN;
    END

    SELECT @NewCode =
        'CUS' + RIGHT('000000' + CAST(ISNULL(MAX(CustomerID), 0) + 1 AS VARCHAR(6)), 6)
    FROM dbo.CUSTOMER;

    INSERT INTO dbo.CUSTOMER
    (
        CustomerCode, FullName, Gender, DateOfBirth,
        NationalID, Phone, Email, [Address],
        Occupation, CustomerType
    )
    VALUES
    (
        @NewCode, @FullName, @Gender, @DateOfBirth,
        @NationalID, @Phone, @Email, @Address,
        @Occupation, @CustomerType
    );

    SELECT *
    FROM dbo.CUSTOMER
    WHERE CustomerID = SCOPE_IDENTITY();
END;
GO

-- Tim kiem khach hang theo ma, ten, CCCD, SDT, email
CREATE OR ALTER PROCEDURE dbo.sp_SearchCustomer
    @Keyword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CustomerID,
        CustomerCode,
        FullName,
        NationalID,
        Phone,
        Email,
        CustomerType,
        [Status],
        CreatedDate
    FROM dbo.CUSTOMER
    WHERE CustomerCode LIKE '%' + @Keyword + '%'
       OR FullName LIKE '%' + @Keyword + '%'
       OR NationalID LIKE '%' + @Keyword + '%'
       OR Phone LIKE '%' + @Keyword + '%'
       OR ISNULL(Email, '') LIKE '%' + @Keyword + '%'
    ORDER BY FullName;
END;
GO

-- ============================================================
-- NHOM 2: TAI KHOAN NGAN HANG
-- Mo tai khoan moi cho khach hang
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_OpenBankAccount
    @CustomerID        INT,
    @BranchID          INT,
    @AccountTypeID     INT,
    @Currency          VARCHAR(10) = 'VND',
    @InitialBalance    DECIMAL(18,2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerStatus VARCHAR(20);
    DECLARE @MinBalance DECIMAL(18,2);
    DECLARE @NewAccountNumber VARCHAR(30);

    SELECT @CustomerStatus = [Status]
    FROM dbo.CUSTOMER
    WHERE CustomerID = @CustomerID;

    IF @CustomerStatus IS NULL
    BEGIN
        RAISERROR(N'Khach hang khong ton tai.', 16, 1);
        RETURN;
    END

    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khach hang khong o trang thai hoat dong.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.BRANCH WHERE BranchID = @BranchID AND [Status] = 'Active')
    BEGIN
        RAISERROR(N'Chi nhanh khong hop le.', 16, 1);
        RETURN;
    END

    SELECT @MinBalance = MinBalance
    FROM dbo.ACCOUNT_TYPE
    WHERE AccountTypeID = @AccountTypeID;

    IF @MinBalance IS NULL
    BEGIN
        RAISERROR(N'Loai tai khoan khong ton tai.', 16, 1);
        RETURN;
    END

    IF @InitialBalance < @MinBalance
    BEGIN
        RAISERROR(N'So du ban dau nho hon muc toi thieu.', 16, 1);
        RETURN;
    END

    SELECT @NewAccountNumber =
        'ACC' + CONVERT(VARCHAR(8), GETDATE(), 112)
        + RIGHT('000000' + CAST(ISNULL(MAX(AccountID), 0) + 1 AS VARCHAR(6)), 6)
    FROM dbo.BANK_ACCOUNT;

    INSERT INTO dbo.BANK_ACCOUNT
    (
        AccountNumber, CustomerID, BranchID,
        AccountTypeID, Balance, Currency
    )
    VALUES
    (
        @NewAccountNumber, @CustomerID, @BranchID,
        @AccountTypeID, @InitialBalance, @Currency
    );

    SELECT *
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = SCOPE_IDENTITY();
END;
GO

-- Nap tien vao tai khoan dich
CREATE OR ALTER PROCEDURE dbo.sp_DepositMoney
    @DestinationAccountID INT,
    @Amount               DECIMAL(18,2),
    @EmployeeID           INT = NULL,
    @Channel              VARCHAR(20),
    @Description          NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AccountStatus VARCHAR(20);
    DECLARE @TransactionTypeID INT;
    DECLARE @TransactionCode VARCHAR(30);

    IF @Amount <= 0
    BEGIN
        RAISERROR(N'So tien nap phai > 0.', 16, 1);
        RETURN;
    END

    SELECT @AccountStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;

    IF @AccountStatus IS NULL
    BEGIN
        RAISERROR(N'Tai khoan dich khong ton tai.', 16, 1);
        RETURN;
    END

    IF @AccountStatus <> 'Active'
    BEGIN
        RAISERROR(N'Tai khoan dich khong hoat dong.', 16, 1);
        RETURN;
    END

    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Deposit';

    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chua co loai giao dich Deposit.', 16, 1);
        RETURN;
    END

    IF @Channel = 'Counter' AND @EmployeeID IS NULL
    BEGIN
        RAISERROR(N'Giao dich tai quay phai co EmployeeID.', 16, 1);
        RETURN;
    END

    SELECT @TransactionCode =
        'TRX' + CONVERT(VARCHAR(8), GETDATE(), 112)
        + RIGHT('00000000' + CAST(ISNULL(MAX(TransactionID), 0) + 1 AS VARCHAR(8)), 8)
    FROM dbo.BANK_TRANSACTION;

    BEGIN TRANSACTION;
        UPDATE dbo.BANK_ACCOUNT
        SET Balance = Balance + @Amount
        WHERE AccountID = @DestinationAccountID;

        INSERT INTO dbo.BANK_TRANSACTION
        (
            TransactionCode, TransactionTypeID,
            SourceAccountID, DestinationAccountID,
            EmployeeID, Channel,
            Amount, Fee, [Description], [Status]
        )
        VALUES
        (
            @TransactionCode, @TransactionTypeID,
            NULL, @DestinationAccountID,
            @EmployeeID, @Channel,
            @Amount, 0, @Description, 'Success'
        );
    COMMIT TRANSACTION;

    SELECT *
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;
END;
GO

-- Rut tien tu tai khoan nguon
CREATE OR ALTER PROCEDURE dbo.sp_WithdrawMoney
    @SourceAccountID INT,
    @Amount          DECIMAL(18,2),
    @Fee             DECIMAL(18,2) = 0,
    @EmployeeID      INT = NULL,
    @Channel         VARCHAR(20),
    @Description     NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Balance DECIMAL(18,2);
    DECLARE @Status VARCHAR(20);
    DECLARE @TransactionTypeID INT;
    DECLARE @TransactionCode VARCHAR(30);

    IF @Amount <= 0
    BEGIN
        RAISERROR(N'So tien rut phai > 0.', 16, 1);
        RETURN;
    END

    IF @Fee < 0
    BEGIN
        RAISERROR(N'Phi khong hop le.', 16, 1);
        RETURN;
    END

    SELECT
        @Balance = Balance,
        @Status = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;

    IF @Status IS NULL
    BEGIN
        RAISERROR(N'Tai khoan nguon khong ton tai.', 16, 1);
        RETURN;
    END

    IF @Status <> 'Active'
    BEGIN
        RAISERROR(N'Tai khoan nguon khong hoat dong.', 16, 1);
        RETURN;
    END

    IF @Balance < (@Amount + @Fee)
    BEGIN
        RAISERROR(N'So du khong du de rut tien.', 16, 1);
        RETURN;
    END

    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Withdraw';

    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chua co loai giao dich Withdraw.', 16, 1);
        RETURN;
    END

    IF @Channel = 'Counter' AND @EmployeeID IS NULL
    BEGIN
        RAISERROR(N'Giao dich tai quay phai co EmployeeID.', 16, 1);
        RETURN;
    END

    SELECT @TransactionCode =
        'TRX' + CONVERT(VARCHAR(8), GETDATE(), 112)
        + RIGHT('00000000' + CAST(ISNULL(MAX(TransactionID), 0) + 1 AS VARCHAR(8)), 8)
    FROM dbo.BANK_TRANSACTION;

    BEGIN TRANSACTION;
        UPDATE dbo.BANK_ACCOUNT
        SET Balance = Balance - (@Amount + @Fee)
        WHERE AccountID = @SourceAccountID;

        INSERT INTO dbo.BANK_TRANSACTION
        (
            TransactionCode, TransactionTypeID,
            SourceAccountID, DestinationAccountID,
            EmployeeID, Channel,
            Amount, Fee, [Description], [Status]
        )
        VALUES
        (
            @TransactionCode, @TransactionTypeID,
            @SourceAccountID, NULL,
            @EmployeeID, @Channel,
            @Amount, @Fee, @Description, 'Success'
        );
    COMMIT TRANSACTION;

    SELECT *
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;
END;
GO

-- Chuyen tien giua hai tai khoan
CREATE OR ALTER PROCEDURE dbo.sp_TransferMoney
    @SourceAccountID      INT,
    @DestinationAccountID INT,
    @Amount               DECIMAL(18,2),
    @Fee                  DECIMAL(18,2) = 0,
    @EmployeeID           INT = NULL,
    @Channel              VARCHAR(20),
    @Description          NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SourceBalance DECIMAL(18,2);
    DECLARE @SourceStatus VARCHAR(20);
    DECLARE @DestinationStatus VARCHAR(20);
    DECLARE @TransactionTypeID INT;
    DECLARE @TransactionCode VARCHAR(30);

    IF @SourceAccountID = @DestinationAccountID
    BEGIN
        RAISERROR(N'Tai khoan nguon va dich khong duoc trung nhau.', 16, 1);
        RETURN;
    END

    IF @Amount <= 0
    BEGIN
        RAISERROR(N'So tien chuyen phai > 0.', 16, 1);
        RETURN;
    END

    IF @Fee < 0
    BEGIN
        RAISERROR(N'Phi khong hop le.', 16, 1);
        RETURN;
    END

    SELECT @SourceBalance = Balance, @SourceStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;

    SELECT @DestinationStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;

    IF @SourceStatus IS NULL OR @DestinationStatus IS NULL
    BEGIN
        RAISERROR(N'Tai khoan nguon hoac dich khong ton tai.', 16, 1);
        RETURN;
    END

    IF @SourceStatus <> 'Active' OR @DestinationStatus <> 'Active'
    BEGIN
        RAISERROR(N'Tai khoan nguon hoac dich khong hoat dong.', 16, 1);
        RETURN;
    END

    IF @SourceBalance < (@Amount + @Fee)
    BEGIN
        RAISERROR(N'So du tai khoan nguon khong du.', 16, 1);
        RETURN;
    END

    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Transfer';

    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chua co loai giao dich Transfer.', 16, 1);
        RETURN;
    END

    IF @Channel = 'Counter' AND @EmployeeID IS NULL
    BEGIN
        RAISERROR(N'Giao dich tai quay phai co EmployeeID.', 16, 1);
        RETURN;
    END

    SELECT @TransactionCode =
        'TRX' + CONVERT(VARCHAR(8), GETDATE(), 112)
        + RIGHT('00000000' + CAST(ISNULL(MAX(TransactionID), 0) + 1 AS VARCHAR(8)), 8)
    FROM dbo.BANK_TRANSACTION;

    BEGIN TRANSACTION;
        UPDATE dbo.BANK_ACCOUNT
        SET Balance = Balance - (@Amount + @Fee)
        WHERE AccountID = @SourceAccountID;

        UPDATE dbo.BANK_ACCOUNT
        SET Balance = Balance + @Amount
        WHERE AccountID = @DestinationAccountID;

        INSERT INTO dbo.BANK_TRANSACTION
        (
            TransactionCode, TransactionTypeID,
            SourceAccountID, DestinationAccountID,
            EmployeeID, Channel,
            Amount, Fee, [Description], [Status]
        )
        VALUES
        (
            @TransactionCode, @TransactionTypeID,
            @SourceAccountID, @DestinationAccountID,
            @EmployeeID, @Channel,
            @Amount, @Fee, @Description, 'Success'
        );
    COMMIT TRANSACTION;

    SELECT
        s.AccountID AS SourceAccountID,
        s.AccountNumber AS SourceAccountNumber,
        s.Balance AS SourceBalance,
        d.AccountID AS DestinationAccountID,
        d.AccountNumber AS DestinationAccountNumber,
        d.Balance AS DestinationBalance
    FROM dbo.BANK_ACCOUNT s
    CROSS JOIN dbo.BANK_ACCOUNT d
    WHERE s.AccountID = @SourceAccountID
      AND d.AccountID = @DestinationAccountID;
END;
GO

-- Cap nhat trang thai tai khoan va luu lich su thay doi
CREATE OR ALTER PROCEDURE dbo.sp_UpdateBankAccountStatus
    @AccountID      INT,
    @NewStatus      VARCHAR(20),
    @ChangedByType  VARCHAR(20),
    @EmployeeID     INT = NULL,
    @Reason         NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus VARCHAR(20);
    DECLARE @Balance DECIMAL(18,2);

    SELECT @CurrentStatus = [Status], @Balance = Balance
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @AccountID;

    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR(N'Tai khoan khong ton tai.', 16, 1);
        RETURN;
    END

    IF @CurrentStatus = @NewStatus
    BEGIN
        RAISERROR(N'Trang thai moi trung trang thai hien tai.', 16, 1);
        RETURN;
    END

    IF @NewStatus = 'Closed' AND @Balance > 0
    BEGIN
        RAISERROR(N'Khong the dong tai khoan khi van con so du.', 16, 1);
        RETURN;
    END

    EXEC sp_set_session_context @key = N'ChangedByType', @value = @ChangedByType;
    EXEC sp_set_session_context @key = N'ChangedEmployeeID', @value = @EmployeeID;
    EXEC sp_set_session_context @key = N'ChangedReason', @value = @Reason;

    UPDATE dbo.BANK_ACCOUNT
    SET [Status] = @NewStatus
    WHERE AccountID = @AccountID;

    EXEC sp_set_session_context @key = N'ChangedByType', @value = NULL;
    EXEC sp_set_session_context @key = N'ChangedEmployeeID', @value = NULL;
    EXEC sp_set_session_context @key = N'ChangedReason', @value = NULL;

    SELECT *
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @AccountID;
END;
GO

-- Lay lich su giao dich cua mot tai khoan theo khoang thoi gian
CREATE OR ALTER PROCEDURE dbo.sp_GetTransactionHistory
    @AccountID   INT,
    @FromDate    DATETIME = NULL,
    @ToDate      DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bt.TransactionID,
        bt.TransactionCode,
        tt.TypeName AS TransactionTypeName,
        bt.SourceAccountID,
        src.AccountNumber AS SourceAccountNumber,
        bt.DestinationAccountID,
        dst.AccountNumber AS DestinationAccountNumber,
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
    WHERE (@AccountID = bt.SourceAccountID OR @AccountID = bt.DestinationAccountID)
      AND (@FromDate IS NULL OR bt.TransactionDate >= @FromDate)
      AND (@ToDate IS NULL OR bt.TransactionDate <= @ToDate)
    ORDER BY bt.TransactionDate DESC, bt.TransactionID DESC;
END;
GO

-- ============================================================
-- NHOM 3: TAI KHOAN ONLINE KHACH HANG
-- Dang ky tai khoan online
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_RegisterCustomerOnlineAccount
    @CustomerID      INT,
    @Username        VARCHAR(50),
    @PasswordHash    VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerStatus VARCHAR(20);

    SELECT @CustomerStatus = [Status]
    FROM dbo.CUSTOMER
    WHERE CustomerID = @CustomerID;

    IF @CustomerStatus IS NULL
    BEGIN
        RAISERROR(N'Khach hang khong ton tai.', 16, 1);
        RETURN;
    END

    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khach hang khong o trang thai hoat dong.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER_ONLINE_ACCOUNT WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR(N'Khach hang da co tai khoan online.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER_ONLINE_ACCOUNT WHERE Username = @Username)
    BEGIN
        RAISERROR(N'Username da ton tai.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.CUSTOMER_ONLINE_ACCOUNT
    (
        CustomerID, Username, PasswordHash, IsActive
    )
    VALUES
    (
        @CustomerID, @Username, @PasswordHash, 1
    );

    SELECT *
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT
    WHERE CustomerOnlineAccountID = SCOPE_IDENTITY();
END;
GO

-- Khoa/mo tai khoan online cua khach hang
CREATE OR ALTER PROCEDURE dbo.sp_UpdateCustomerOnlineAccountStatus
    @CustomerID INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.CUSTOMER_ONLINE_ACCOUNT
    SET IsActive = @IsActive
    WHERE CustomerID = @CustomerID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Tai khoan online khong ton tai.', 16, 1);
        RETURN;
    END

    SELECT *
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT
    WHERE CustomerID = @CustomerID;
END;
GO

-- Dang nhap tai khoan online cua khach hang
CREATE OR ALTER PROCEDURE dbo.sp_CustomerOnlineLogin
    @Username       VARCHAR(50),
    @PasswordHash   VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerOnlineAccountID INT;
    DECLARE @IsActive BIT;

    SELECT
        @CustomerOnlineAccountID = CustomerOnlineAccountID,
        @IsActive = IsActive
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT
    WHERE Username = @Username
      AND PasswordHash = @PasswordHash;

    IF @CustomerOnlineAccountID IS NULL
    BEGIN
        RAISERROR(N'Sai username hoac password.', 16, 1);
        RETURN;
    END

    IF @IsActive = 0
    BEGIN
        RAISERROR(N'Tai khoan online dang bi khoa.', 16, 1);
        RETURN;
    END

    UPDATE dbo.CUSTOMER_ONLINE_ACCOUNT
    SET LastLogin = GETDATE()
    WHERE CustomerOnlineAccountID = @CustomerOnlineAccountID;

    SELECT
        coa.CustomerOnlineAccountID,
        coa.CustomerID,
        coa.Username,
        coa.LastLogin,
        coa.IsActive,
        c.FullName,
        c.Phone,
        c.Email
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT coa
    INNER JOIN dbo.CUSTOMER c
        ON coa.CustomerID = c.CustomerID
    WHERE coa.CustomerOnlineAccountID = @CustomerOnlineAccountID;
END;
GO

-- ============================================================
-- NHOM 4: THE NGAN HANG
-- Phat hanh the moi cho tai khoan
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_IssueCard
    @AccountID    INT,
    @ExpiryDate   DATE,
    @CardType     VARCHAR(20),
    @PINHash      VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountStatus VARCHAR(20);
    DECLARE @CardNumber VARCHAR(30);

    SELECT @AccountStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @AccountID;

    IF @AccountStatus IS NULL
    BEGIN
        RAISERROR(N'Tai khoan khong ton tai.', 16, 1);
        RETURN;
    END

    IF @AccountStatus <> 'Active'
    BEGIN
        RAISERROR(N'Chi duoc phat hanh the cho tai khoan dang hoat dong.', 16, 1);
        RETURN;
    END

    SELECT @CardNumber =
        '9704' + RIGHT('0000000000000000' + CAST(ISNULL(MAX(CardID), 0) + 1 AS VARCHAR(16)), 16)
    FROM dbo.CARD;

    INSERT INTO dbo.CARD
    (
        CardNumber, AccountID, ExpiryDate,
        CardType, PINHash, [Status]
    )
    VALUES
    (
        @CardNumber, @AccountID, @ExpiryDate,
        @CardType, @PINHash, 'Active'
    );

    SELECT *
    FROM dbo.CARD
    WHERE CardID = SCOPE_IDENTITY();
END;
GO

-- ============================================================
-- NHOM 5: KHOAN VAY
-- Tao khoan vay moi
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreateLoan
    @CustomerID        INT,
    @BranchID          INT,
    @EmployeeID        INT,
    @LoanTypeID        INT,
    @PrincipalAmount   DECIMAL(18,2),
    @InterestRate      DECIMAL(5,2),
    @TermMonths        INT,
    @StartDate         DATE,
    @EndDate           DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerStatus VARCHAR(20);
    DECLARE @EmployeeStatus VARCHAR(20);
    DECLARE @MaxAmount DECIMAL(18,2);
    DECLARE @MaxTermMonths INT;
    DECLARE @LoanCode VARCHAR(30);

    SELECT @CustomerStatus = [Status]
    FROM dbo.CUSTOMER
    WHERE CustomerID = @CustomerID;

    IF @CustomerStatus IS NULL
    BEGIN
        RAISERROR(N'Khach hang khong ton tai.', 16, 1);
        RETURN;
    END

    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khach hang khong o trang thai hoat dong.', 16, 1);
        RETURN;
    END

    SELECT @EmployeeStatus = [Status]
    FROM dbo.EMPLOYEE
    WHERE EmployeeID = @EmployeeID;

    IF @EmployeeStatus IS NULL OR @EmployeeStatus <> 'Active'
    BEGIN
        RAISERROR(N'Nhan vien xu ly khong hop le.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.BRANCH WHERE BranchID = @BranchID AND [Status] = 'Active')
    BEGIN
        RAISERROR(N'Chi nhanh khong hop le.', 16, 1);
        RETURN;
    END

    SELECT @MaxAmount = MaxAmount, @MaxTermMonths = MaxTermMonths
    FROM dbo.LOAN_TYPE
    WHERE LoanTypeID = @LoanTypeID;

    IF @MaxAmount IS NULL
    BEGIN
        RAISERROR(N'Loai khoan vay khong ton tai.', 16, 1);
        RETURN;
    END

    IF @PrincipalAmount > @MaxAmount
    BEGIN
        RAISERROR(N'So tien vay vuot muc toi da cua loai vay.', 16, 1);
        RETURN;
    END

    IF @TermMonths > @MaxTermMonths
    BEGIN
        RAISERROR(N'Thoi han vay vuot muc toi da.', 16, 1);
        RETURN;
    END

    SELECT @LoanCode =
        'LOAN' + CONVERT(VARCHAR(8), GETDATE(), 112)
        + RIGHT('000000' + CAST(ISNULL(MAX(LoanID), 0) + 1 AS VARCHAR(6)), 6)
    FROM dbo.LOAN;

    INSERT INTO dbo.LOAN
    (
        LoanCode, CustomerID, BranchID, EmployeeID, LoanTypeID,
        PrincipalAmount, InterestRate, TermMonths,
        StartDate, EndDate, [Status]
    )
    VALUES
    (
        @LoanCode, @CustomerID, @BranchID, @EmployeeID, @LoanTypeID,
        @PrincipalAmount, @InterestRate, @TermMonths,
        @StartDate, @EndDate, 'Pending'
    );

    SELECT *
    FROM dbo.LOAN
    WHERE LoanID = SCOPE_IDENTITY();
END;
GO

-- Ghi nhan mot lan thanh toan cho khoan vay
CREATE OR ALTER PROCEDURE dbo.sp_PayLoanInstallment
    @LoanID            INT,
    @PrincipalPaid     DECIMAL(18,2),
    @InterestPaid      DECIMAL(18,2),
    @PenaltyFee        DECIMAL(18,2) = 0,
    @PaymentChannel    VARCHAR(20),
    @EmployeeID        INT = NULL,
    @Note              NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LoanStatus VARCHAR(20);
    DECLARE @RemainingPrincipal DECIMAL(18,2);
    DECLARE @AmountPaid DECIMAL(18,2);

    SET @AmountPaid = @PrincipalPaid + @InterestPaid + @PenaltyFee;

    IF @AmountPaid <= 0
    BEGIN
        RAISERROR(N'So tien thanh toan phai > 0.', 16, 1);
        RETURN;
    END

    SELECT @LoanStatus = [Status]
    FROM dbo.LOAN
    WHERE LoanID = @LoanID;

    IF @LoanStatus IS NULL
    BEGIN
        RAISERROR(N'Khoan vay khong ton tai.', 16, 1);
        RETURN;
    END

    IF @LoanStatus IN ('Rejected', 'Completed')
    BEGIN
        RAISERROR(N'Khoan vay khong o trang thai cho phep thanh toan.', 16, 1);
        RETURN;
    END

    IF @PaymentChannel = 'Counter' AND @EmployeeID IS NULL
    BEGIN
        RAISERROR(N'Thanh toan tai quay phai co EmployeeID.', 16, 1);
        RETURN;
    END

    SELECT @RemainingPrincipal = dbo.fn_GetLoanRemainingPrincipal(@LoanID);

    IF @PrincipalPaid > @RemainingPrincipal
    BEGIN
        RAISERROR(N'Goc tra vuot qua du no goc con lai.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
        INSERT INTO dbo.LOAN_PAYMENT
        (
            LoanID, AmountPaid, PrincipalPaid, InterestPaid,
            PenaltyFee, PaymentChannel, EmployeeID, Note
        )
        VALUES
        (
            @LoanID, @AmountPaid, @PrincipalPaid, @InterestPaid,
            @PenaltyFee, @PaymentChannel, @EmployeeID, @Note
        );

        IF dbo.fn_GetLoanRemainingPrincipal(@LoanID) <= 0
        BEGIN
            UPDATE dbo.LOAN
            SET [Status] = 'Completed'
            WHERE LoanID = @LoanID;
        END
        ELSE
        BEGIN
            UPDATE dbo.LOAN
            SET [Status] = 'Paying'
            WHERE LoanID = @LoanID
              AND [Status] IN ('Approved', 'Pending', 'Overdue', 'Paying');
        END
    COMMIT TRANSACTION;

    SELECT *
    FROM dbo.vw_LoanStatus
    WHERE LoanID = @LoanID;
END;
GO

-- Cap nhat cac khoan vay qua han dua tren ngay hien tai
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

    SELECT *
    FROM dbo.vw_OverdueLoans
    ORDER BY EndDate;
END;
GO

-- ============================================================
-- NHOM 6: HE THONG / NHAN SU
-- Dang nhap he thong cho nhan vien
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_SystemUserLogin
    @Username       VARCHAR(50),
    @PasswordHash   VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT;
    DECLARE @IsActive BIT;

    SELECT @UserID = UserID, @IsActive = IsActive
    FROM dbo.[SYSTEM_USER]
    WHERE Username = @Username
      AND PasswordHash = @PasswordHash;

    IF @UserID IS NULL
    BEGIN
        RAISERROR(N'Sai username hoac password.', 16, 1);
        RETURN;
    END

    IF @IsActive = 0
    BEGIN
        RAISERROR(N'Tai khoan he thong dang bi khoa.', 16, 1);
        RETURN;
    END

    UPDATE dbo.[SYSTEM_USER]
    SET LastLogin = GETDATE()
    WHERE UserID = @UserID;

    SELECT
        su.UserID,
        su.Username,
        su.LastLogin,
        su.IsActive,
        e.EmployeeID,
        e.FullName,
        e.BranchID,
        e.RoleID,
        r.RoleName
    FROM dbo.[SYSTEM_USER] su
    INNER JOIN dbo.EMPLOYEE e
        ON su.EmployeeID = e.EmployeeID
    INNER JOIN dbo.[ROLE] r
        ON e.RoleID = r.RoleID
    WHERE su.UserID = @UserID;
END;
GO

-- Tao tai khoan dang nhap he thong cho nhan vien
CREATE OR ALTER PROCEDURE dbo.sp_CreateSystemUser
    @EmployeeID      INT,
    @Username        VARCHAR(50),
    @PasswordHash    VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeStatus VARCHAR(20);

    SELECT @EmployeeStatus = [Status]
    FROM dbo.EMPLOYEE
    WHERE EmployeeID = @EmployeeID;

    IF @EmployeeStatus IS NULL
    BEGIN
        RAISERROR(N'Nhan vien khong ton tai.', 16, 1);
        RETURN;
    END

    IF @EmployeeStatus NOT IN ('Active', 'Inactive', 'Suspended')
    BEGIN
        RAISERROR(N'Nhan vien khong hop le de cap tai khoan he thong.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.[SYSTEM_USER] WHERE EmployeeID = @EmployeeID)
    BEGIN
        RAISERROR(N'Nhan vien nay da co tai khoan he thong.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.[SYSTEM_USER] WHERE Username = @Username)
    BEGIN
        RAISERROR(N'Username da ton tai.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.[SYSTEM_USER]
    (
        EmployeeID,
        Username,
        PasswordHash,
        IsActive
    )
    VALUES
    (
        @EmployeeID,
        @Username,
        @PasswordHash,
        1
    );

    SELECT *
    FROM dbo.[SYSTEM_USER]
    WHERE UserID = SCOPE_IDENTITY();
END;
GO
