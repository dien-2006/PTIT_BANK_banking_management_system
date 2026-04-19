USE BankingManagementDB;
GO

-- ============================================================
-- FILE: 00_seed_reference_data.sql
-- Muc dich:
-- Seed du lieu danh muc nen de cac procedure nghiep vu hoat dong.
-- Bao gom: vai tro, chi nhanh, loai tai khoan, loai giao dich, loai vay.
-- Chay file nay sau khi da tao bang bang create_table.sql.
-- ============================================================

SET NOCOUNT ON;
GO

-- Seed danh muc vai tro nhan su trong he thong
MERGE dbo.[ROLE] AS target
USING (
    VALUES
        (N'Admin', N'Quan tri he thong'),
        (N'Teller', N'Giao dich vien'),
        (N'Loan Officer', N'Can bo tin dung'),
        (N'Branch Manager', N'Quan ly chi nhanh')
) AS source(RoleName, [Description])
ON target.RoleName = source.RoleName
WHEN MATCHED THEN
    UPDATE SET [Description] = source.[Description]
WHEN NOT MATCHED THEN
    INSERT (RoleName, [Description]) VALUES (source.RoleName, source.[Description]);
GO

-- Seed danh muc chi nhanh mac dinh
MERGE dbo.BRANCH AS target
USING (
    VALUES
        ('BR001', N'Chi nhanh Ha Noi', N'122 Hoang Quoc Viet', N'Ha Noi', '02473000001'),
        ('BR002', N'Chi nhanh Da Nang', N'08 Nguyen Van Linh', N'Da Nang', '02367300002'),
        ('BR003', N'Chi nhanh TP HCM', N'235 Nguyen Van Cu', N'TP HCM', '02873000003')
) AS source(BranchCode, BranchName, [Address], City, Phone)
ON target.BranchCode = source.BranchCode
WHEN MATCHED THEN
    UPDATE SET
        BranchName = source.BranchName,
        [Address] = source.[Address],
        City = source.City,
        Phone = source.Phone,
        [Status] = 'Active'
WHEN NOT MATCHED THEN
    INSERT (BranchCode, BranchName, [Address], City, Phone, OpenDate, [Status])
    VALUES (source.BranchCode, source.BranchName, source.[Address], source.City, source.Phone, CAST(GETDATE() AS DATE), 'Active');
GO

-- Seed danh muc loai tai khoan ngan hang
MERGE dbo.ACCOUNT_TYPE AS target
USING (
    VALUES
        (N'Thanh toan', 50000, 0.10, N'Tai khoan thanh toan ca nhan'),
        (N'Tiet kiem', 1000000, 4.50, N'Tai khoan tiet kiem co ky han'),
        (N'Doanh nghiep', 1000000, 0.20, N'Tai khoan thanh toan doanh nghiep')
) AS source(TypeName, MinBalance, InterestRate, [Description])
ON target.TypeName = source.TypeName
WHEN MATCHED THEN
    UPDATE SET
        MinBalance = source.MinBalance,
        InterestRate = source.InterestRate,
        [Description] = source.[Description]
WHEN NOT MATCHED THEN
    INSERT (TypeName, MinBalance, InterestRate, [Description])
    VALUES (source.TypeName, source.MinBalance, source.InterestRate, source.[Description]);
GO

-- Seed danh muc loai giao dich ma cac procedure nap/rut/chuyen can su dung
MERGE dbo.TRANSACTION_TYPE AS target
USING (
    VALUES
        (N'Deposit', N'Nop tien vao tai khoan'),
        (N'Withdraw', N'Rut tien tu tai khoan'),
        (N'Transfer', N'Chuyen khoan giua hai tai khoan')
) AS source(TypeName, [Description])
ON target.TypeName = source.TypeName
WHEN MATCHED THEN
    UPDATE SET [Description] = source.[Description]
WHEN NOT MATCHED THEN
    INSERT (TypeName, [Description]) VALUES (source.TypeName, source.[Description]);
GO

-- Seed danh muc loai khoan vay
MERGE dbo.LOAN_TYPE AS target
USING (
    VALUES
        (N'Vay tin chap', 100000000, 12.50, 36, N'Khoan vay khong tai san dam bao'),
        (N'Vay the chap', 2000000000, 9.20, 240, N'Khoan vay co tai san dam bao'),
        (N'Vay tieu dung', 300000000, 14.00, 60, N'Khoan vay tieu dung ca nhan')
) AS source(LoanTypeName, MaxAmount, DefaultInterestRate, MaxTermMonths, [Description])
ON target.LoanTypeName = source.LoanTypeName
WHEN MATCHED THEN
    UPDATE SET
        MaxAmount = source.MaxAmount,
        DefaultInterestRate = source.DefaultInterestRate,
        MaxTermMonths = source.MaxTermMonths,
        [Description] = source.[Description]
WHEN NOT MATCHED THEN
    INSERT (LoanTypeName, MaxAmount, DefaultInterestRate, MaxTermMonths, [Description])
    VALUES (source.LoanTypeName, source.MaxAmount, source.DefaultInterestRate, source.MaxTermMonths, source.[Description]);
GO
