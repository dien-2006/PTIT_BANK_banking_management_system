USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 03_triggers.sql
-- Muc dich:
-- Trigger tu dong dong bo nghiep vu khi du lieu thay doi.
-- ============================================================

-- Trigger luu lich su thay doi trang thai tai khoan
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
        d.[Status],
        i.[Status],
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

-- Trigger dong bo trang thai the khi tai khoan bi khoa/bi dong
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
            WHEN i.[Status] = 'Closed' THEN 'Cancelled'
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
