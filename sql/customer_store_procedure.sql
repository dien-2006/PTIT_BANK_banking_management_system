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
