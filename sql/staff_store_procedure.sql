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
    