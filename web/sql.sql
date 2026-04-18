USE BankingManagementDB;
GO

-- STORED PROCEDURE NGHIỆP VỤ
-- Thêm khách hàng
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
    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE NationalID = @NationalID)
    BEGIN
        RAISERROR(N'NationalID đã tồn tại.', 16, 1);
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE Phone = @Phone)
    BEGIN
        RAISERROR(N'Số điện thoại đã tồn tại.', 16, 1);
        RETURN;
    END
    IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.CUSTOMER WHERE Email = @Email)
    BEGIN
        RAISERROR(N'Email đã tồn tại.', 16, 1);
        RETURN;
    END
    SELECT @NewCode = 'CUS' + RIGHT('000000' + CAST(ISNULL(MAX(CustomerID), 0) + 1 AS VARCHAR(6)), 6)
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
    SELECT
        CustomerID,
        CustomerCode,
        FullName,
        Phone,
        CustomerType,
        [Status]
    FROM dbo.CUSTOMER
    WHERE CustomerID = SCOPE_IDENTITY();
END;
GO
-- Tìm kiếm khách hàng
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
-- Mở tài khoản ngân hàng
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
        RAISERROR(N'Khách hàng không tồn tại.', 16, 1);
        RETURN;
    END
    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khách hàng không ở trạng thái hoạt động.', 16, 1);
        RETURN;
    END
    SELECT @MinBalance = MinBalance
    FROM dbo.ACCOUNT_TYPE
    WHERE AccountTypeID = @AccountTypeID;
    IF @MinBalance IS NULL
    BEGIN
        RAISERROR(N'Loại tài khoản không tồn tại.', 16, 1);
        RETURN;
    END
    IF @InitialBalance < @MinBalance
    BEGIN
        RAISERROR(N'Số dư ban đầu nhỏ hơn mức tối thiểu của loại tài khoản.', 16, 1);
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
    SELECT
        AccountID,
        AccountNumber,
        CustomerID,
        BranchID,
        AccountTypeID,
        OpenDate,
        Balance,
        [Status],
        Currency
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = SCOPE_IDENTITY();
END;
GO
-- Nạp tiền
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
        RAISERROR(N'Số tiền nạp phải > 0.', 16, 1);
        RETURN;
    END
    SELECT @AccountStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;
    IF @AccountStatus IS NULL
    BEGIN
        RAISERROR(N'Tài khoản đích không tồn tại.', 16, 1);
        RETURN;
    END
    IF @AccountStatus <> 'Active'
    BEGIN
        RAISERROR(N'Tài khoản đích không hoạt động.', 16, 1);
        RETURN;
    END
    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Deposit';
    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chưa có loại giao dịch Deposit trong TRANSACTION_TYPE.', 16, 1);
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
    SELECT
        AccountID,
        AccountNumber,
        Balance,
        [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;
END;
GO
-- Rút tiền
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
        RAISERROR(N'Số tiền rút phải > 0.', 16, 1);
        RETURN;
    END
    IF @Fee < 0
    BEGIN
        RAISERROR(N'Phí không hợp lệ.', 16, 1);
        RETURN;
    END
    SELECT
        @Balance = Balance,
        @Status = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;
    IF @Status IS NULL
    BEGIN
        RAISERROR(N'Tài khoản nguồn không tồn tại.', 16, 1);
        RETURN;
    END
    IF @Status <> 'Active'
    BEGIN
        RAISERROR(N'Tài khoản nguồn không hoạt động.', 16, 1);
        RETURN;
    END
    IF @Balance < (@Amount + @Fee)
    BEGIN
        RAISERROR(N'Số dư không đủ để rút tiền.', 16, 1);
        RETURN;
    END
    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Withdraw';
    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chưa có loại giao dịch Withdraw trong TRANSACTION_TYPE.', 16, 1);
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
    SELECT
        AccountID,
        AccountNumber,
        Balance,
        [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;
END;
GO
-- Chuyển khoản
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
        RAISERROR(N'Tài khoản nguồn và đích không được trùng nhau.', 16, 1);
        RETURN;
    END
    IF @Amount <= 0
    BEGIN
        RAISERROR(N'Số tiền chuyển phải > 0.', 16, 1);
        RETURN;
    END
    IF @Fee < 0
    BEGIN
        RAISERROR(N'Phí không hợp lệ.', 16, 1);
        RETURN;
    END
    SELECT
        @SourceBalance = Balance,
        @SourceStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @SourceAccountID;
    SELECT
        @DestinationStatus = [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @DestinationAccountID;
    IF @SourceStatus IS NULL
    BEGIN
        RAISERROR(N'Tài khoản nguồn không tồn tại.', 16, 1);
        RETURN;
    END
    IF @DestinationStatus IS NULL
    BEGIN
        RAISERROR(N'Tài khoản đích không tồn tại.', 16, 1);
        RETURN;
    END
    IF @SourceStatus <> 'Active'
    BEGIN
        RAISERROR(N'Tài khoản nguồn không hoạt động.', 16, 1);
        RETURN;
    END
    IF @DestinationStatus <> 'Active'
    BEGIN
        RAISERROR(N'Tài khoản đích không hoạt động.', 16, 1);
        RETURN;
    END
    IF @SourceBalance < (@Amount + @Fee)
    BEGIN
        RAISERROR(N'Số dư tài khoản nguồn không đủ.', 16, 1);
        RETURN;
    END
    SELECT @TransactionTypeID = TransactionTypeID
    FROM dbo.TRANSACTION_TYPE
    WHERE TypeName = N'Transfer';
    IF @TransactionTypeID IS NULL
    BEGIN
        RAISERROR(N'Chưa có loại giao dịch Transfer trong TRANSACTION_TYPE.', 16, 1);
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
-- Khóa / mở / đóng tài khoản
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
    SELECT
        @CurrentStatus = [Status],
        @Balance = Balance
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @AccountID;
    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR(N'Tài khoản không tồn tại.', 16, 1);
        RETURN;
    END
    IF @CurrentStatus = @NewStatus
    BEGIN
        RAISERROR(N'Trạng thái mới trùng trạng thái hiện tại.', 16, 1);
        RETURN;
    END
    IF @NewStatus = 'Closed' AND @Balance > 0
    BEGIN
        RAISERROR(N'Không thể đóng tài khoản khi vẫn còn số dư.', 16, 1);
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
    SELECT
        AccountID,
        AccountNumber,
        Balance,
        [Status]
    FROM dbo.BANK_ACCOUNT
    WHERE AccountID = @AccountID;
END;
GO
-- Phát hành thẻ
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
        RAISERROR(N'Tài khoản không tồn tại.', 16, 1);
        RETURN;
    END
    IF @AccountStatus <> 'Active'
    BEGIN
        RAISERROR(N'Chỉ được phát hành thẻ cho tài khoản đang hoạt động.', 16, 1);
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
-- Tạo khoản vay
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
    DECLARE @MaxAmount DECIMAL(18,2);
    DECLARE @MaxTermMonths INT;
    DECLARE @LoanCode VARCHAR(30);
    SELECT @CustomerStatus = [Status]
    FROM dbo.CUSTOMER
    WHERE CustomerID = @CustomerID;
    IF @CustomerStatus IS NULL
    BEGIN
        RAISERROR(N'Khách hàng không tồn tại.', 16, 1);
        RETURN;
    END
    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khách hàng không ở trạng thái hoạt động.', 16, 1);
        RETURN;
    END
    SELECT
        @MaxAmount = MaxAmount,
        @MaxTermMonths = MaxTermMonths
    FROM dbo.LOAN_TYPE
    WHERE LoanTypeID = @LoanTypeID;
    IF @MaxAmount IS NULL
    BEGIN
        RAISERROR(N'Loại khoản vay không tồn tại.', 16, 1);
        RETURN;
    END
    IF @PrincipalAmount > @MaxAmount
    BEGIN
        RAISERROR(N'Số tiền vay vượt mức tối đa của loại vay.', 16, 1);
        RETURN;
    END
    IF @TermMonths > @MaxTermMonths
    BEGIN
        RAISERROR(N'Thời hạn vay vượt mức tối đa của loại vay.', 16, 1);
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
-- Thanh toán khoản vay
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
        RAISERROR(N'Số tiền thanh toán phải > 0.', 16, 1);
        RETURN;
    END
    SELECT @LoanStatus = [Status]
    FROM dbo.LOAN
    WHERE LoanID = @LoanID;
    IF @LoanStatus IS NULL
    BEGIN
        RAISERROR(N'Khoản vay không tồn tại.', 16, 1);
        RETURN;
    END
    IF @LoanStatus IN ('Rejected', 'Completed')
    BEGIN
        RAISERROR(N'Khoản vay không ở trạng thái cho phép thanh toán.', 16, 1);
        RETURN;
    END
    SELECT @RemainingPrincipal = dbo.fn_GetLoanRemainingPrincipal(@LoanID);
    IF @PrincipalPaid > @RemainingPrincipal
    BEGIN
        RAISERROR(N'Tiền gốc thanh toán vượt quá dư nợ còn lại.', 16, 1);
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
        SET @RemainingPrincipal = dbo.fn_GetLoanRemainingPrincipal(@LoanID);
        IF @RemainingPrincipal = 0
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
    SELECT
        l.LoanID,
        l.LoanCode,
        l.[Status],
        dbo.fn_GetLoanRemainingPrincipal(l.LoanID) AS RemainingPrincipal
    FROM dbo.LOAN l
    WHERE l.LoanID = @LoanID;
END;
GO
-- Lịch sử giao dịch theo tài khoản
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
        src.AccountNumber AS SourceAccountNumber,
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
-- TRIGGER TỰ GHI LỊCH SỬ ĐỔI TRẠNG THÁI TÀI KHOẢN
CREATE OR ALTER TRIGGER dbo.trg_BankAccount_StatusHistory
ON dbo.BANK_ACCOUNT
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE([Status])
        RETURN;

    INSERT INTO dbo.ACCOUNT_STATUS_HISTORY
    (
        AccountID,
        OldStatus,
        NewStatus,
        ChangedDate,
        ChangedByType,
        EmployeeID,
        Reason
    )
    SELECT
        d.AccountID,
        d.[Status] AS OldStatus,
        i.[Status] AS NewStatus,
        GETDATE(),
        CAST(ISNULL(SESSION_CONTEXT(N'ChangedByType'), 'System') AS VARCHAR(20)),
        TRY_CAST(SESSION_CONTEXT(N'ChangedEmployeeID') AS INT),
        CAST(SESSION_CONTEXT(N'ChangedReason') AS NVARCHAR(255))
    FROM inserted i
    INNER JOIN deleted d
        ON i.AccountID = d.AccountID
    WHERE ISNULL(d.[Status], '') <> ISNULL(i.[Status], '');
END;
GO
USE BankingManagementDB;
GO

-- CUSTOMER
CREATE INDEX IX_CUSTOMER_FullName
ON dbo.CUSTOMER(FullName);
GO
CREATE INDEX IX_CUSTOMER_NationalID
ON dbo.CUSTOMER(NationalID);
GO
CREATE INDEX IX_CUSTOMER_Phone
ON dbo.CUSTOMER(Phone);
GO
CREATE INDEX IX_CUSTOMER_CustomerType_Status
ON dbo.CUSTOMER(CustomerType, [Status]);
GO
-- EMPLOYEE
CREATE INDEX IX_EMPLOYEE_BranchID
ON dbo.EMPLOYEE(BranchID);
GO
CREATE INDEX IX_EMPLOYEE_RoleID
ON dbo.EMPLOYEE(RoleID);
GO
CREATE INDEX IX_EMPLOYEE_Status
ON dbo.EMPLOYEE([Status]);
GO
-- BANK_ACCOUNT
CREATE INDEX IX_BANK_ACCOUNT_CustomerID
ON dbo.BANK_ACCOUNT(CustomerID);
GO
CREATE INDEX IX_BANK_ACCOUNT_BranchID
ON dbo.BANK_ACCOUNT(BranchID);
GO
CREATE INDEX IX_BANK_ACCOUNT_AccountTypeID
ON dbo.BANK_ACCOUNT(AccountTypeID);
GO
CREATE INDEX IX_BANK_ACCOUNT_Status
ON dbo.BANK_ACCOUNT([Status]);
GO
CREATE INDEX IX_BANK_ACCOUNT_Customer_Status
ON dbo.BANK_ACCOUNT(CustomerID, [Status]);
GO
-- CARD
CREATE INDEX IX_CARD_AccountID
ON dbo.CARD(AccountID);
GO
CREATE INDEX IX_CARD_Status
ON dbo.CARD([Status]);
GO
-- ACCOUNT_STATUS_HISTORY
CREATE INDEX IX_ACCOUNT_STATUS_HISTORY_AccountID_ChangedDate
ON dbo.ACCOUNT_STATUS_HISTORY(AccountID, ChangedDate DESC);
GO
-- BANK_TRANSACTION
CREATE INDEX IX_BANK_TRANSACTION_TransactionDate
ON dbo.BANK_TRANSACTION(TransactionDate);
GO
CREATE INDEX IX_BANK_TRANSACTION_SourceAccountID
ON dbo.BANK_TRANSACTION(SourceAccountID);
GO
CREATE INDEX IX_BANK_TRANSACTION_DestinationAccountID
ON dbo.BANK_TRANSACTION(DestinationAccountID);
GO
CREATE INDEX IX_BANK_TRANSACTION_EmployeeID
ON dbo.BANK_TRANSACTION(EmployeeID);
GO
CREATE INDEX IX_BANK_TRANSACTION_TransactionTypeID
ON dbo.BANK_TRANSACTION(TransactionTypeID);
GO
CREATE INDEX IX_BANK_TRANSACTION_Channel_Status
ON dbo.BANK_TRANSACTION(Channel, [Status]);
GO
CREATE INDEX IX_BANK_TRANSACTION_SourceAccountID_TransactionDate
ON dbo.BANK_TRANSACTION(SourceAccountID, TransactionDate DESC);
GO
CREATE INDEX IX_BANK_TRANSACTION_DestinationAccountID_TransactionDate
ON dbo.BANK_TRANSACTION(DestinationAccountID, TransactionDate DESC);
GO
-- LOAN
CREATE INDEX IX_LOAN_CustomerID
ON dbo.LOAN(CustomerID);
GO
CREATE INDEX IX_LOAN_BranchID
ON dbo.LOAN(BranchID);
GO
CREATE INDEX IX_LOAN_EmployeeID
ON dbo.LOAN(EmployeeID);
GO
CREATE INDEX IX_LOAN_LoanTypeID
ON dbo.LOAN(LoanTypeID);
GO
CREATE INDEX IX_LOAN_Status
ON dbo.LOAN([Status]);
GO
CREATE INDEX IX_LOAN_CustomerID_Status
ON dbo.LOAN(CustomerID, [Status]);
GO
-- LOAN_PAYMENT
CREATE INDEX IX_LOAN_PAYMENT_LoanID
ON dbo.LOAN_PAYMENT(LoanID);
GO
CREATE INDEX IX_LOAN_PAYMENT_PaymentDate
ON dbo.LOAN_PAYMENT(PaymentDate);
GO
CREATE INDEX IX_LOAN_PAYMENT_LoanID_PaymentDate
ON dbo.LOAN_PAYMENT(LoanID, PaymentDate DESC);
GO
-- Đăng ký tài khoản online cho khách hàng
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
        RAISERROR(N'Khách hàng không tồn tại.', 16, 1);
        RETURN;
    END
    IF @CustomerStatus <> 'Active'
    BEGIN
        RAISERROR(N'Khách hàng không ở trạng thái hoạt động.', 16, 1);
        RETURN;
    END
    IF EXISTS (
        SELECT 1
        FROM dbo.CUSTOMER_ONLINE_ACCOUNT
        WHERE CustomerID = @CustomerID
    )
    BEGIN
        RAISERROR(N'Khách hàng này đã có tài khoản online.', 16, 1);
        RETURN;
    END
    IF EXISTS (
        SELECT 1
        FROM dbo.CUSTOMER_ONLINE_ACCOUNT
        WHERE Username = @Username
    )
    BEGIN
        RAISERROR(N'Username đã tồn tại.', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.CUSTOMER_ONLINE_ACCOUNT
    (
        CustomerID,
        Username,
        PasswordHash,
        IsActive
    )
    VALUES
    (
        @CustomerID,
        @Username,
        @PasswordHash,
        1
    );
    SELECT *
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT
    WHERE CustomerOnlineAccountID = SCOPE_IDENTITY();
END;
GO
-- Khóa / mở tài khoản online
CREATE OR ALTER PROCEDURE dbo.sp_UpdateCustomerOnlineAccountStatus
    @CustomerID   INT,
    @IsActive     BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.CUSTOMER_ONLINE_ACCOUNT
        WHERE CustomerID = @CustomerID
    )
    BEGIN
        RAISERROR(N'Khách hàng chưa có tài khoản online.', 16, 1);
        RETURN;
    END
    UPDATE dbo.CUSTOMER_ONLINE_ACCOUNT
    SET IsActive = @IsActive
    WHERE CustomerID = @CustomerID;
    SELECT *
    FROM dbo.CUSTOMER_ONLINE_ACCOUNT
    WHERE CustomerID = @CustomerID;
END;
GO
-- Đăng nhập tài khoản online khách hàng
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
        RAISERROR(N'Sai username hoặc password.', 16, 1);
        RETURN;
    END
    IF @IsActive = 0
    BEGIN
        RAISERROR(N'Tài khoản online đang bị khóa.', 16, 1);
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
-- Đăng nhập hệ thống cho nhân viên
CREATE OR ALTER PROCEDURE dbo.sp_SystemUserLogin
    @Username       VARCHAR(50),
    @PasswordHash   VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserID INT;
    DECLARE @IsActive BIT;
    SELECT
        @UserID = UserID,
        @IsActive = IsActive
    FROM dbo.[SYSTEM_USER]
    WHERE Username = @Username
      AND PasswordHash = @PasswordHash;
    IF @UserID IS NULL
    BEGIN
        RAISERROR(N'Sai username hoặc password.', 16, 1);
        RETURN;
    END
    IF @IsActive = 0
    BEGIN
        RAISERROR(N'Tài khoản hệ thống đang bị khóa.', 16, 1);
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
-- Tạo tài khoản đăng nhập cho nhân viên
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
        RAISERROR(N'Nhân viên không tồn tại.', 16, 1);
        RETURN;
    END
    IF @EmployeeStatus NOT IN ('Active', 'Inactive', 'Suspended')
    BEGIN
        RAISERROR(N'Nhân viên không hợp lệ để cấp tài khoản hệ thống.', 16, 1);
        RETURN;
    END
    IF EXISTS (
        SELECT 1
        FROM dbo.[SYSTEM_USER]
        WHERE EmployeeID = @EmployeeID
    )
    BEGIN
        RAISERROR(N'Nhân viên này đã có tài khoản hệ thống.', 16, 1);
        RETURN;
    END
    IF EXISTS (
        SELECT 1
        FROM dbo.[SYSTEM_USER]
        WHERE Username = @Username
    )
    BEGIN
        RAISERROR(N'Username đã tồn tại.', 16, 1);
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
