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