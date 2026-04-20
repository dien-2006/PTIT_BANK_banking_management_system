
-- 1. BRANCH
INSERT INTO dbo.BRANCH (BranchCode, BranchName, [Address], City, Phone, OpenDate, [Status]) VALUES
('BR001', N'Chi nhánh Hà Nội Trung Tâm', N'12 Tràng Thi, Hoàn Kiếm', N'Hà Nội', '02438880001', '2018-01-15', 'Active'),
('BR002', N'Chi nhánh Cầu Giấy', N'85 Xuân Thủy, Cầu Giấy',N'Hà Nội', '02438880002', '2019-05-10', 'Active'),
('BR003', N'Chi nhánh Đống Đa', N'120 Tây Sơn, Đống Đa',N'Hà Nội', '02438880003', '2020-09-20', 'Active');
GO
-- 2. ROLE
INSERT INTO dbo.[ROLE] (RoleName, [Description]) VALUES
(N'Admin', N'Quản trị hệ thống'),
(N'Teller', N'Nhân viên giao dịch'),
(N'Loan Officer', N'Nhân viên tín dụng');
GO
-- 3. EMPLOYEE
INSERT INTO dbo.EMPLOYEE (BranchID, RoleID, FullName, Gender, DateOfBirth, Phone, Email, HireDate, Salary, [Status])VALUES
((SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR001'),
 (SELECT RoleID FROM dbo.[ROLE] WHERE RoleName = N'Admin'),
 N'Nguyễn Ngọc Diện', 'Male', '2006-01-23', '0909000001', 'emp.dien@bank.local', '2023-01-10', 25000000, 'Active'),
((SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR002'),
 (SELECT RoleID FROM dbo.[ROLE] WHERE RoleName = N'Teller'),
 N'Đỗ Khánh Linh', 'Female', '2006-12-18', '0909000002', 'emp.linh@bank.local', '2023-02-15', 18000000, 'Active'),
((SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR003'),
 (SELECT RoleID FROM dbo.[ROLE] WHERE RoleName = N'Loan Officer'),
 N'Lương Minh Quân', 'Male', '2006-04-18', '0909000003', 'emp.quan@bank.local', '2023-03-20', 22000000, 'Active');
GO
-- 4. SYSTEM_USER
INSERT INTO dbo.SYSTEM_USER (EmployeeID, Username, PasswordHash, LastLogin, IsActive) VALUES
((SELECT EmployeeID FROM dbo.EMPLOYEE WHERE Email = 'emp.dien@bank.local'), 'dien', '123456', '2026-04-19 08:30:00', 1),
((SELECT EmployeeID FROM dbo.EMPLOYEE WHERE Email = 'emp.linh@bank.local'), 'linh', '123456', '2026-04-19 09:00:00', 1),
((SELECT EmployeeID FROM dbo.EMPLOYEE WHERE Email = 'emp.quan@bank.local'), 'quan', '123456', '2026-04-19 09:15:00', 1);
GO
-- 5. CUSTOMER
INSERT INTO dbo.CUSTOMER (CustomerCode, FullName, Gender, DateOfBirth, NationalID, Phone, Email, [Address], Occupation, CustomerType, CreatedDate, [Status]) VALUES
('CUST001',N'Nguyễn Ngọc Diện','Male','2004-09-10','001204000111','0912000001','cus.dien@gmail.com',N'Hoàn Kiếm,Hà Nội',N'Trưởng nhóm','Individual','2026-01-05','Active'),
('CUST002', N'Đỗ Khánh Linh','Female','2004-12-22','001204000222','0912000002','cus.linh@gmail.com',N'Cầu Giấy,Hà Nội', N'Thành viên','Individual','2026-01-06','Active'),
('CUST003', N'Lương Minh Quân',  'Male',   '2004-04-18', '001204000333', '0912000003', 'cus.quan@gmail.com',N'Đống Đa,Hà Nội',N'Thành viên','Individual','2026-01-07','Active');
GO
-- 6. CUSTOMER_ONLINE_ACCOUNT
INSERT INTO dbo.CUSTOMER_ONLINE_ACCOUNT (CustomerID, Username, PasswordHash, LastLogin, IsActive, RegisteredDate) VALUES
((SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST001'), 'dien_nn', '123456', '2026-04-19 20:15:00', 1, '2026-01-05 10:00:00'),
((SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST002'), 'linh_dk', '123456', '2026-04-19 20:30:00', 1, '2026-01-06 10:30:00'),
((SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST003'), 'quan_lm', '123456', '2026-04-19 21:00:00', 1, '2026-01-07 11:00:00');
GO
-- 7. ACCOUNT_TYPE
INSERT INTO dbo.ACCOUNT_TYPE (TypeName, MinBalance, InterestRate, [Description]) VALUES
(N'Thanh toán', 50000, 0.10, N'Tài khoản thanh toán'),
(N'Tiết kiệm', 1000000, 4.80, N'Tài khoản tiết kiệm'),
(N'Lương', 0, 0.05, N'Tài khoản nhận lương');
GO
-- 8. BANK_ACCOUNT
INSERT INTO dbo.BANK_ACCOUNT(AccountNumber, CustomerID, BranchID, AccountTypeID, OpenDate, Balance, [Status], Currency) VALUES
('100000000001',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST001'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR001'),
 (SELECT AccountTypeID FROM dbo.ACCOUNT_TYPE WHERE TypeName = N'Thanh toán'),
 '2026-01-05', 18000000, 'Active', 'VND'),
('100000000002',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST002'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR002'),
 (SELECT AccountTypeID FROM dbo.ACCOUNT_TYPE WHERE TypeName = N'Thanh toán'),
 '2026-01-06', 22000000, 'Active', 'VND'),
('100000000003',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST003'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR003'),
 (SELECT AccountTypeID FROM dbo.ACCOUNT_TYPE WHERE TypeName = N'Thanh toán'),
 '2026-01-07', 25000000, 'Active', 'VND');
GO
-- 9. CARD
INSERT INTO dbo.CARD (CardNumber, AccountID, IssueDate, ExpiryDate, CardType, PINHash, [Status]) VALUES
('9704000000000001', (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'), '2026-01-06', '2031-01-06', 'Debit', 'PINHASH001', 'Active'),
('9704000000000002', (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'), '2026-01-07', '2031-01-07', 'Debit', 'PINHASH002', 'Active'),
('9704000000000003', (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'), '2026-01-08', '2031-01-08', 'Debit', 'PINHASH003', 'Active');
GO
-- 10. ACCOUNT_STATUS_HISTORY
INSERT INTO dbo.ACCOUNT_STATUS_HISTORY (AccountID, OldStatus, NewStatus, ChangedDate, ChangedByType, EmployeeID, Reason) VALUES
((SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 'Inactive', 'Active', '2026-01-05 09:30:00', 'Employee',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Kích hoạt tài khoản mới'),
((SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 'Inactive', 'Active', '2026-01-06 09:45:00', 'Employee',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Kích hoạt tài khoản mới'),
((SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 'Inactive', 'Active', '2026-01-07 10:00:00', 'Employee',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Kích hoạt tài khoản mới');
GO
-- 11. TRANSACTION_TYPE
INSERT INTO dbo.TRANSACTION_TYPE (TypeName, [Description]) VALUES
(N'Deposit', N'Nạp tiền'),
(N'Withdraw', N'Rút tiền'),
(N'Transfer', N'Chuyển khoản'),
(N'LoanPayment', N'Thanh toán khoản vay'),
(N'BillPayment', N'Thanh toán hóa đơn');
GO
-- 12. BANK_TRANSACTION
INSERT INTO dbo.BANK_TRANSACTION(TransactionCode, TransactionTypeID, SourceAccountID, DestinationAccountID, EmployeeID, Channel, Amount, Fee, TransactionDate, [Description], [Status]) VALUES
('TXN000001',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Deposit'),
 NULL,
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 5000000, 0, '2026-02-01 09:00:00',
 N'Nguyễn Ngọc Diện nộp tiền mặt',
 'Success'),
('TXN000002',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 NULL,
 'MobileBanking',
 1200000, 3300, '2026-02-05 20:15:00',
 N'Nguyễn Ngọc Diện chuyển khoản cho Đỗ Khánh Linh',
 'Success'),
('TXN000003',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Withdraw'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 NULL,
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 800000, 0, '2026-02-12 10:20:00',
 N'Nguyễn Ngọc Diện rút tiền tại quầy',
 'Success'),
('TXN000004',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 NULL,
 'InternetBanking',
 1500000, 3300, '2026-02-18 21:00:00',
 N'Nguyễn Ngọc Diện chuyển khoản cho Lương Minh Quân',
 'Success'),
('TXN000005',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Deposit'),
 NULL,
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 4000000, 0, '2026-02-02 09:30:00',
 N'Đỗ Khánh Linh nộp tiền mặt',
 'Success'),
('TXN000006',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 NULL,
 'MobileBanking',
 900000, 3300, '2026-02-06 19:45:00',
 N'Đỗ Khánh Linh chuyển khoản cho Nguyễn Ngọc Diện',
 'Success'),

('TXN000007',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Withdraw'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 NULL,
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 1000000, 0, '2026-02-14 11:00:00',
 N'Đỗ Khánh Linh rút tiền tại quầy',
 'Success'),
('TXN000008',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 NULL,
 'InternetBanking',
 2000000, 3300, '2026-02-20 20:30:00',
 N'Đỗ Khánh Linh chuyển khoản cho Lương Minh Quân',
 'Success'),
('TXN000009',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Deposit'),
 NULL,
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 6000000, 0, '2026-02-03 08:45:00',
 N'Lương Minh Quân nộp tiền mặt',
 'Success'),
('TXN000010',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000001'),
 NULL,
 'MobileBanking',
 1700000, 3300, '2026-02-08 21:20:00',
 N'Lương Minh Quân chuyển khoản cho Nguyễn Ngọc Diện',
 'Success'),
('TXN000011',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Withdraw'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 NULL,
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 'Counter',
 1200000, 0, '2026-02-16 14:10:00',
 N'Lương Minh Quân rút tiền tại quầy',
 'Success'),
('TXN000012',
 (SELECT TransactionTypeID FROM dbo.TRANSACTION_TYPE WHERE TypeName = N'Transfer'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000003'),
 (SELECT AccountID FROM dbo.BANK_ACCOUNT WHERE AccountNumber = '100000000002'),
 NULL,
 'InternetBanking',
 1400000, 3300, '2026-02-22 18:50:00',
 N'Lương Minh Quân chuyển khoản cho Đỗ Khánh Linh',
 'Success');
GO
-- 13. LOAN_TYPE
INSERT INTO dbo.LOAN_TYPE (LoanTypeName, MaxAmount, DefaultInterestRate, MaxTermMonths, [Description]) VALUES
(N'Vay sinh viên', 50000000, 5.50, 60, N'Hỗ trợ học tập'),
(N'Vay tiêu dùng', 150000000, 9.20, 48, N'Phục vụ nhu cầu cá nhân'),
(N'Vay mua xe', 300000000, 8.50, 72, N'Vay mua phương tiện');
GO
-- 14. LOAN
INSERT INTO dbo.LOAN (LoanCode, CustomerID, BranchID, EmployeeID, LoanTypeID, PrincipalAmount, InterestRate, TermMonths, StartDate, EndDate, [Status]) VALUES
('LN000001',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST001'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR001'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Lương Minh Quân'),
 (SELECT LoanTypeID FROM dbo.LOAN_TYPE WHERE LoanTypeName = N'Vay sinh viên'),
 30000000, 5.50, 36, '2026-03-01', '2029-03-01', 'Approved'),
('LN000002',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST002'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR002'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Lương Minh Quân'),
 (SELECT LoanTypeID FROM dbo.LOAN_TYPE WHERE LoanTypeName = N'Vay tiêu dùng'),
 40000000, 9.20, 24, '2026-03-05', '2028-03-05', 'Paying'),
('LN000003',
 (SELECT CustomerID FROM dbo.CUSTOMER WHERE CustomerCode = 'CUST003'),
 (SELECT BranchID FROM dbo.BRANCH WHERE BranchCode = 'BR003'),
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Lương Minh Quân'),
 (SELECT LoanTypeID FROM dbo.LOAN_TYPE WHERE LoanTypeName = N'Vay mua xe'),
 90000000, 8.50, 48, '2026-03-10', '2030-03-10', 'Approved');
GO
-- 15. LOAN_PAYMENT
INSERT INTO dbo.LOAN_PAYMENT
(LoanID, PaymentDate, AmountPaid, PrincipalPaid, InterestPaid, PenaltyFee, PaymentChannel, EmployeeID, Note)
VALUES
((SELECT LoanID FROM dbo.LOAN WHERE LoanCode = 'LN000001'),
 '2026-04-01 10:00:00',
 3000000, 2500000, 500000, 0,
 'Counter',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Thanh toán kỳ đầu của Nguyễn Ngọc Diện'),
((SELECT LoanID FROM dbo.LOAN WHERE LoanCode = 'LN000002'),
 '2026-04-02 10:30:00',
 3500000, 2800000, 700000, 0,
 'Counter',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Thanh toán kỳ đầu của Đỗ Khánh Linh'),
((SELECT LoanID FROM dbo.LOAN WHERE LoanCode = 'LN000003'),
 '2026-04-03 11:00:00',
 5000000, 4200000, 800000, 0,
 'Counter',
 (SELECT EmployeeID FROM dbo.EMPLOYEE WHERE FullName = N'Đỗ Khánh Linh'),
 N'Thanh toán kỳ đầu của Lương Minh Quân');
GO