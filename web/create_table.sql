USE master;
GO

-- Tạo database nếu chưa có
IF DB_ID('BankingManagementDB') IS NULL
BEGIN
    CREATE DATABASE BankingManagementDB;
END
GO

USE BankingManagementDB;
GO

/* ==============================================================
1. XÓA BẢNG NẾU ĐÃ TỒN TẠI (THEO THỨ TỰ PHỤ THUỘC)
============================================================== */
IF OBJECT_ID('dbo.LOAN_PAYMENT', 'U') IS NOT NULL DROP TABLE dbo.LOAN_PAYMENT;
IF OBJECT_ID('dbo.LOAN', 'U') IS NOT NULL DROP TABLE dbo.LOAN;
IF OBJECT_ID('dbo.LOAN_TYPE', 'U') IS NOT NULL DROP TABLE dbo.LOAN_TYPE;

IF OBJECT_ID('dbo.BANK_TRANSACTION', 'U') IS NOT NULL DROP TABLE dbo.BANK_TRANSACTION;
IF OBJECT_ID('dbo.TRANSACTION_TYPE', 'U') IS NOT NULL DROP TABLE dbo.TRANSACTION_TYPE;

IF OBJECT_ID('dbo.ACCOUNT_STATUS_HISTORY', 'U') IS NOT NULL DROP TABLE dbo.ACCOUNT_STATUS_HISTORY;
IF OBJECT_ID('dbo.CARD', 'U') IS NOT NULL DROP TABLE dbo.CARD;
IF OBJECT_ID('dbo.BANK_ACCOUNT', 'U') IS NOT NULL DROP TABLE dbo.BANK_ACCOUNT;
IF OBJECT_ID('dbo.ACCOUNT_TYPE', 'U') IS NOT NULL DROP TABLE dbo.ACCOUNT_TYPE;

IF OBJECT_ID('dbo.CUSTOMER_ONLINE_ACCOUNT', 'U') IS NOT NULL DROP TABLE dbo.CUSTOMER_ONLINE_ACCOUNT;
IF OBJECT_ID('dbo.CUSTOMER', 'U') IS NOT NULL DROP TABLE dbo.CUSTOMER;

IF OBJECT_ID('dbo.SYSTEM_USER', 'U') IS NOT NULL DROP TABLE dbo.[SYSTEM_USER];
IF OBJECT_ID('dbo.EMPLOYEE', 'U') IS NOT NULL DROP TABLE dbo.EMPLOYEE;
IF OBJECT_ID('dbo.ROLE', 'U') IS NOT NULL DROP TABLE dbo.ROLE;
IF OBJECT_ID('dbo.BRANCH', 'U') IS NOT NULL DROP TABLE dbo.BRANCH;
GO

/* ==============================================================
2. BRANCH
============================================================== */
CREATE TABLE dbo.BRANCH
(
    BranchID       INT IDENTITY(1,1) NOT NULL,
    BranchCode     VARCHAR(20) NOT NULL,
    BranchName     NVARCHAR(100) NOT NULL,
    [Address]      NVARCHAR(255) NOT NULL,
    City           NVARCHAR(100) NOT NULL,
    Phone          VARCHAR(15) NULL,
    OpenDate       DATE NOT NULL
        CONSTRAINT DF_BRANCH_OpenDate DEFAULT (CAST(GETDATE() AS DATE)),
    [Status]       VARCHAR(20) NOT NULL
        CONSTRAINT DF_BRANCH_Status DEFAULT ('Active'),

    CONSTRAINT PK_BRANCH PRIMARY KEY (BranchID),
    CONSTRAINT UQ_BRANCH_BranchCode UNIQUE (BranchCode),
    CONSTRAINT UQ_BRANCH_Phone UNIQUE (Phone),

    CONSTRAINT CK_BRANCH_Status
        CHECK ([Status] IN ('Active', 'Inactive', 'Closed'))
);
GO

/* ==============================================================
3. ROLE
============================================================== */
CREATE TABLE dbo.[ROLE]
(
    RoleID         INT IDENTITY(1,1) NOT NULL,
    RoleName       NVARCHAR(50) NOT NULL,
    [Description]  NVARCHAR(255) NULL,

    CONSTRAINT PK_ROLE PRIMARY KEY (RoleID),
    CONSTRAINT UQ_ROLE_RoleName UNIQUE (RoleName)
);
GO

/* ==============================================================
4. EMPLOYEE
============================================================== */
CREATE TABLE dbo.EMPLOYEE
(
    EmployeeID     INT IDENTITY(1,1) NOT NULL,
    BranchID       INT NOT NULL,
    RoleID         INT NOT NULL,
    FullName       NVARCHAR(100) NOT NULL,
    Gender         VARCHAR(10) NOT NULL,
    DateOfBirth    DATE NOT NULL,
    Phone          VARCHAR(15) NOT NULL,
    Email          VARCHAR(100) NOT NULL,
    HireDate       DATE NOT NULL
        CONSTRAINT DF_EMPLOYEE_HireDate DEFAULT (CAST(GETDATE() AS DATE)),
    Salary         DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_EMPLOYEE_Salary DEFAULT (0),
    [Status]       VARCHAR(20) NOT NULL
        CONSTRAINT DF_EMPLOYEE_Status DEFAULT ('Active'),

    CONSTRAINT PK_EMPLOYEE PRIMARY KEY (EmployeeID),
    CONSTRAINT UQ_EMPLOYEE_Phone UNIQUE (Phone),
    CONSTRAINT UQ_EMPLOYEE_Email UNIQUE (Email),

    CONSTRAINT FK_EMPLOYEE_BRANCH
        FOREIGN KEY (BranchID) REFERENCES dbo.BRANCH(BranchID),

    CONSTRAINT FK_EMPLOYEE_ROLE
        FOREIGN KEY (RoleID) REFERENCES dbo.[ROLE](RoleID),

    CONSTRAINT CK_EMPLOYEE_Gender
        CHECK (Gender IN ('Male', 'Female', 'Other')),

    CONSTRAINT CK_EMPLOYEE_Salary
        CHECK (Salary >= 0),

    CONSTRAINT CK_EMPLOYEE_Status
        CHECK ([Status] IN ('Active', 'Inactive', 'Suspended', 'Resigned')),

    CONSTRAINT CK_EMPLOYEE_DateOfBirth_HireDate
        CHECK (DateOfBirth < HireDate)
);
GO

/* ==============================================================
5. SYSTEM_USER
============================================================== */
CREATE TABLE dbo.[SYSTEM_USER]
(
    UserID         INT IDENTITY(1,1) NOT NULL,
    EmployeeID     INT NOT NULL,
    Username       VARCHAR(50) NOT NULL,
    PasswordHash   VARCHAR(255) NOT NULL,
    LastLogin      DATETIME NULL,
    IsActive       BIT NOT NULL
        CONSTRAINT DF_SYSTEM_USER_IsActive DEFAULT (1),

    CONSTRAINT PK_SYSTEM_USER PRIMARY KEY (UserID),
    CONSTRAINT UQ_SYSTEM_USER_EmployeeID UNIQUE (EmployeeID),
    CONSTRAINT UQ_SYSTEM_USER_Username UNIQUE (Username),

    CONSTRAINT FK_SYSTEM_USER_EMPLOYEE
        FOREIGN KEY (EmployeeID) REFERENCES dbo.EMPLOYEE(EmployeeID)
);
GO

/* ==============================================================
6. CUSTOMER
============================================================== */
CREATE TABLE dbo.CUSTOMER
(
    CustomerID      INT IDENTITY(1,1) NOT NULL,
    CustomerCode    VARCHAR(20) NOT NULL,
    FullName        NVARCHAR(100) NOT NULL,
    Gender          VARCHAR(10) NOT NULL,
    DateOfBirth     DATE NOT NULL,
    NationalID      VARCHAR(20) NOT NULL,
    Phone           VARCHAR(15) NOT NULL,
    Email           VARCHAR(100) NULL,
    [Address]       NVARCHAR(255) NOT NULL,
    Occupation      NVARCHAR(100) NULL,
    CustomerType    VARCHAR(20) NOT NULL
        CONSTRAINT DF_CUSTOMER_CustomerType DEFAULT ('Individual'),
    CreatedDate     DATE NOT NULL
        CONSTRAINT DF_CUSTOMER_CreatedDate DEFAULT (CAST(GETDATE() AS DATE)),
    [Status]        VARCHAR(20) NOT NULL
        CONSTRAINT DF_CUSTOMER_Status DEFAULT ('Active'),

    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_CUSTOMER_CustomerCode UNIQUE (CustomerCode),
    CONSTRAINT UQ_CUSTOMER_NationalID UNIQUE (NationalID),
    CONSTRAINT UQ_CUSTOMER_Phone UNIQUE (Phone),
    CONSTRAINT UQ_CUSTOMER_Email UNIQUE (Email),

    CONSTRAINT CK_CUSTOMER_Gender
        CHECK (Gender IN ('Male', 'Female', 'Other')),

    CONSTRAINT CK_CUSTOMER_CustomerType
        CHECK (CustomerType IN ('Individual', 'Business')),

    CONSTRAINT CK_CUSTOMER_Status
        CHECK ([Status] IN ('Active', 'Inactive', 'Blacklisted')),

    CONSTRAINT CK_CUSTOMER_CreatedDate_DateOfBirth
        CHECK (CreatedDate >= DateOfBirth)
);
GO

/*==============================================================
7. CUSTOMER_ONLINE_ACCOUNT
==============================================================*/
CREATE TABLE dbo.CUSTOMER_ONLINE_ACCOUNT
(
    CustomerOnlineAccountID   INT IDENTITY(1,1) NOT NULL,
    CustomerID                INT NOT NULL,
    Username                  VARCHAR(50) NOT NULL,
    PasswordHash              VARCHAR(255) NOT NULL,
    LastLogin                 DATETIME NULL,
    IsActive                  BIT NOT NULL
        CONSTRAINT DF_CUSTOMER_ONLINE_ACCOUNT_IsActive DEFAULT (1),
    RegisteredDate            DATETIME NOT NULL
        CONSTRAINT DF_CUSTOMER_ONLINE_ACCOUNT_RegisteredDate DEFAULT (GETDATE()),

    CONSTRAINT PK_CUSTOMER_ONLINE_ACCOUNT PRIMARY KEY (CustomerOnlineAccountID),
    CONSTRAINT UQ_CUSTOMER_ONLINE_ACCOUNT_CustomerID UNIQUE (CustomerID),
    CONSTRAINT UQ_CUSTOMER_ONLINE_ACCOUNT_Username UNIQUE (Username),

    CONSTRAINT FK_CUSTOMER_ONLINE_ACCOUNT_CUSTOMER
        FOREIGN KEY (CustomerID) REFERENCES dbo.CUSTOMER(CustomerID)
);
GO

/*==============================================================
8. ACCOUNT_TYPE
==============================================================*/
CREATE TABLE dbo.ACCOUNT_TYPE
(
    AccountTypeID   INT IDENTITY(1,1) NOT NULL,
    TypeName        NVARCHAR(50) NOT NULL,
    MinBalance      DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_ACCOUNT_TYPE_MinBalance DEFAULT (0),
    InterestRate    DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_ACCOUNT_TYPE_InterestRate DEFAULT (0),
    [Description]   NVARCHAR(255) NULL,

    CONSTRAINT PK_ACCOUNT_TYPE PRIMARY KEY (AccountTypeID),
    CONSTRAINT UQ_ACCOUNT_TYPE_TypeName UNIQUE (TypeName),

    CONSTRAINT CK_ACCOUNT_TYPE_MinBalance
        CHECK (MinBalance >= 0),

    CONSTRAINT CK_ACCOUNT_TYPE_InterestRate
        CHECK (InterestRate >= 0)
);
GO

/*==============================================================
9. BANK_ACCOUNT
==============================================================*/
CREATE TABLE dbo.BANK_ACCOUNT
(
    AccountID        INT IDENTITY(1,1) NOT NULL,
    AccountNumber    VARCHAR(30) NOT NULL,
    CustomerID       INT NOT NULL,
    BranchID         INT NOT NULL,
    AccountTypeID    INT NOT NULL,
    OpenDate         DATE NOT NULL
        CONSTRAINT DF_BANK_ACCOUNT_OpenDate DEFAULT (CAST(GETDATE() AS DATE)),
    Balance          DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_BANK_ACCOUNT_Balance DEFAULT (0),
    [Status]         VARCHAR(20) NOT NULL
        CONSTRAINT DF_BANK_ACCOUNT_Status DEFAULT ('Active'),
    Currency         VARCHAR(10) NOT NULL
        CONSTRAINT DF_BANK_ACCOUNT_Currency DEFAULT ('VND'),

    CONSTRAINT PK_BANK_ACCOUNT PRIMARY KEY (AccountID),
    CONSTRAINT UQ_BANK_ACCOUNT_AccountNumber UNIQUE (AccountNumber),

    CONSTRAINT FK_BANK_ACCOUNT_CUSTOMER
        FOREIGN KEY (CustomerID) REFERENCES dbo.CUSTOMER(CustomerID),

    CONSTRAINT FK_BANK_ACCOUNT_BRANCH
        FOREIGN KEY (BranchID) REFERENCES dbo.BRANCH(BranchID),

    CONSTRAINT FK_BANK_ACCOUNT_ACCOUNT_TYPE
        FOREIGN KEY (AccountTypeID) REFERENCES dbo.ACCOUNT_TYPE(AccountTypeID),

    CONSTRAINT CK_BANK_ACCOUNT_Balance
        CHECK (Balance >= 0),

    CONSTRAINT CK_BANK_ACCOUNT_Status
        CHECK ([Status] IN ('Active', 'Inactive', 'Blocked', 'Closed')),

    CONSTRAINT CK_BANK_ACCOUNT_Currency
        CHECK (Currency IN ('VND', 'USD', 'EUR'))
);
GO

/*==============================================================
10. CARD
==============================================================*/
CREATE TABLE dbo.CARD
(
    CardID          INT IDENTITY(1,1) NOT NULL,
    CardNumber      VARCHAR(30) NOT NULL,
    AccountID       INT NOT NULL,
    IssueDate       DATE NOT NULL
        CONSTRAINT DF_CARD_IssueDate DEFAULT (CAST(GETDATE() AS DATE)),
    ExpiryDate      DATE NOT NULL,
    CardType        VARCHAR(20) NOT NULL,
    PINHash         VARCHAR(255) NOT NULL,
    [Status]        VARCHAR(20) NOT NULL
        CONSTRAINT DF_CARD_Status DEFAULT ('Active'),

    CONSTRAINT PK_CARD PRIMARY KEY (CardID),
    CONSTRAINT UQ_CARD_CardNumber UNIQUE (CardNumber),

    CONSTRAINT FK_CARD_BANK_ACCOUNT
        FOREIGN KEY (AccountID) REFERENCES dbo.BANK_ACCOUNT(AccountID),

    CONSTRAINT CK_CARD_ExpiryDate_IssueDate
        CHECK (ExpiryDate > IssueDate),

    CONSTRAINT CK_CARD_CardType
        CHECK (CardType IN ('Debit', 'Credit', 'ATM')),

    CONSTRAINT CK_CARD_Status
        CHECK ([Status] IN ('Active', 'Blocked', 'Expired', 'Cancelled'))
);
GO

/*==============================================================
11. ACCOUNT_STATUS_HISTORY
==============================================================*/
CREATE TABLE dbo.ACCOUNT_STATUS_HISTORY
(
    HistoryID        BIGINT IDENTITY(1,1) NOT NULL,
    AccountID        INT NOT NULL,
    OldStatus        VARCHAR(20) NOT NULL,
    NewStatus        VARCHAR(20) NOT NULL,
    ChangedDate      DATETIME NOT NULL
        CONSTRAINT DF_ACCOUNT_STATUS_HISTORY_ChangedDate DEFAULT (GETDATE()),
    ChangedByType    VARCHAR(20) NOT NULL,
    EmployeeID       INT NULL,
    Reason           NVARCHAR(255) NULL,

    CONSTRAINT PK_ACCOUNT_STATUS_HISTORY PRIMARY KEY (HistoryID),

    CONSTRAINT FK_ACCOUNT_STATUS_HISTORY_BANK_ACCOUNT
        FOREIGN KEY (AccountID) REFERENCES dbo.BANK_ACCOUNT(AccountID),

    CONSTRAINT FK_ACCOUNT_STATUS_HISTORY_EMPLOYEE
        FOREIGN KEY (EmployeeID) REFERENCES dbo.EMPLOYEE(EmployeeID),

    CONSTRAINT CK_ACCOUNT_STATUS_HISTORY_OldStatus
        CHECK (OldStatus IN ('Active', 'Inactive', 'Blocked', 'Closed')),

    CONSTRAINT CK_ACCOUNT_STATUS_HISTORY_NewStatus
        CHECK (NewStatus IN ('Active', 'Inactive', 'Blocked', 'Closed')),

    CONSTRAINT CK_ACCOUNT_STATUS_HISTORY_StatusDifferent
        CHECK (OldStatus <> NewStatus),

    CONSTRAINT CK_ACCOUNT_STATUS_HISTORY_ChangedByType
        CHECK (ChangedByType IN ('Employee', 'Customer', 'System')),

    CONSTRAINT CK_ACCOUNT_STATUS_HISTORY_EmployeeRule
        CHECK (
            (ChangedByType = 'Employee' AND EmployeeID IS NOT NULL)
            OR
            (ChangedByType IN ('Customer', 'System') AND EmployeeID IS NULL)
        )
);
GO

/*==============================================================
12. TRANSACTION_TYPE
==============================================================*/
CREATE TABLE dbo.TRANSACTION_TYPE
(
    TransactionTypeID   INT IDENTITY(1,1) NOT NULL,
    TypeName            NVARCHAR(50) NOT NULL,
    [Description]       NVARCHAR(255) NULL,

    CONSTRAINT PK_TRANSACTION_TYPE PRIMARY KEY (TransactionTypeID),
    CONSTRAINT UQ_TRANSACTION_TYPE_TypeName UNIQUE (TypeName)
);
GO

/*==============================================================
13. BANK_TRANSACTION
==============================================================*/
CREATE TABLE dbo.BANK_TRANSACTION
(
    TransactionID         BIGINT IDENTITY(1,1) NOT NULL,
    TransactionCode       VARCHAR(30) NOT NULL,
    TransactionTypeID     INT NOT NULL,
    SourceAccountID       INT NULL,
    DestinationAccountID  INT NULL,
    EmployeeID            INT NULL,
    Channel               VARCHAR(20) NOT NULL,
    Amount                DECIMAL(18,2) NOT NULL,
    Fee                   DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_BANK_TRANSACTION_Fee DEFAULT (0),
    TransactionDate       DATETIME NOT NULL
        CONSTRAINT DF_BANK_TRANSACTION_TransactionDate DEFAULT (GETDATE()),
    [Description]         NVARCHAR(255) NULL,
    [Status]              VARCHAR(20) NOT NULL
        CONSTRAINT DF_BANK_TRANSACTION_Status DEFAULT ('Success'),

    CONSTRAINT PK_BANK_TRANSACTION PRIMARY KEY (TransactionID),
    CONSTRAINT UQ_BANK_TRANSACTION_TransactionCode UNIQUE (TransactionCode),

    CONSTRAINT FK_BANK_TRANSACTION_TRANSACTION_TYPE
        FOREIGN KEY (TransactionTypeID) REFERENCES dbo.TRANSACTION_TYPE(TransactionTypeID),

    CONSTRAINT FK_BANK_TRANSACTION_SourceAccount
        FOREIGN KEY (SourceAccountID) REFERENCES dbo.BANK_ACCOUNT(AccountID),

    CONSTRAINT FK_BANK_TRANSACTION_DestinationAccount
        FOREIGN KEY (DestinationAccountID) REFERENCES dbo.BANK_ACCOUNT(AccountID),

    CONSTRAINT FK_BANK_TRANSACTION_EMPLOYEE
        FOREIGN KEY (EmployeeID) REFERENCES dbo.EMPLOYEE(EmployeeID),

    CONSTRAINT CK_BANK_TRANSACTION_Amount
        CHECK (Amount > 0),

    CONSTRAINT CK_BANK_TRANSACTION_Fee
        CHECK (Fee >= 0),

    CONSTRAINT CK_BANK_TRANSACTION_Status
        CHECK ([Status] IN ('Pending', 'Success', 'Failed', 'Cancelled')),

    CONSTRAINT CK_BANK_TRANSACTION_Channel
        CHECK (Channel IN ('Counter', 'InternetBanking', 'MobileBanking', 'ATM', 'System')),

    CONSTRAINT CK_BANK_TRANSACTION_AtLeastOneAccount
        CHECK (SourceAccountID IS NOT NULL OR DestinationAccountID IS NOT NULL),

    CONSTRAINT CK_BANK_TRANSACTION_DifferentAccounts
        CHECK (
            SourceAccountID IS NULL
            OR DestinationAccountID IS NULL
            OR SourceAccountID <> DestinationAccountID
        ),

    CONSTRAINT CK_BANK_TRANSACTION_EmployeeRule
        CHECK (
            (Channel = 'Counter' AND EmployeeID IS NOT NULL)
            OR
            (Channel IN ('InternetBanking', 'MobileBanking', 'ATM', 'System') AND EmployeeID IS NULL)
        )
);
GO

/*==============================================================
14. LOAN_TYPE
==============================================================*/
CREATE TABLE dbo.LOAN_TYPE
(
    LoanTypeID             INT IDENTITY(1,1) NOT NULL,
    LoanTypeName           NVARCHAR(50) NOT NULL,
    MaxAmount              DECIMAL(18,2) NOT NULL,
    DefaultInterestRate    DECIMAL(5,2) NOT NULL,
    MaxTermMonths          INT NOT NULL,
    [Description]          NVARCHAR(255) NULL,

    CONSTRAINT PK_LOAN_TYPE PRIMARY KEY (LoanTypeID),
    CONSTRAINT UQ_LOAN_TYPE_LoanTypeName UNIQUE (LoanTypeName),

    CONSTRAINT CK_LOAN_TYPE_MaxAmount
        CHECK (MaxAmount > 0),

    CONSTRAINT CK_LOAN_TYPE_DefaultInterestRate
        CHECK (DefaultInterestRate >= 0),

    CONSTRAINT CK_LOAN_TYPE_MaxTermMonths
        CHECK (MaxTermMonths > 0)
);
GO

/*==============================================================
15. LOAN
==============================================================*/
CREATE TABLE dbo.LOAN
(
    LoanID              INT IDENTITY(1,1) NOT NULL,
    LoanCode            VARCHAR(30) NOT NULL,
    CustomerID          INT NOT NULL,
    BranchID            INT NOT NULL,
    EmployeeID          INT NOT NULL,
    LoanTypeID          INT NOT NULL,
    PrincipalAmount     DECIMAL(18,2) NOT NULL,
    InterestRate        DECIMAL(5,2) NOT NULL,
    TermMonths          INT NOT NULL,
    StartDate           DATE NOT NULL,
    EndDate             DATE NOT NULL,
    [Status]            VARCHAR(20) NOT NULL
        CONSTRAINT DF_LOAN_Status DEFAULT ('Pending'),

    CONSTRAINT PK_LOAN PRIMARY KEY (LoanID),
    CONSTRAINT UQ_LOAN_LoanCode UNIQUE (LoanCode),

    CONSTRAINT FK_LOAN_CUSTOMER
        FOREIGN KEY (CustomerID) REFERENCES dbo.CUSTOMER(CustomerID),

    CONSTRAINT FK_LOAN_BRANCH
        FOREIGN KEY (BranchID) REFERENCES dbo.BRANCH(BranchID),

    CONSTRAINT FK_LOAN_EMPLOYEE
        FOREIGN KEY (EmployeeID) REFERENCES dbo.EMPLOYEE(EmployeeID),

    CONSTRAINT FK_LOAN_LOAN_TYPE
        FOREIGN KEY (LoanTypeID) REFERENCES dbo.LOAN_TYPE(LoanTypeID),

    CONSTRAINT CK_LOAN_PrincipalAmount
        CHECK (PrincipalAmount > 0),

    CONSTRAINT CK_LOAN_InterestRate
        CHECK (InterestRate >= 0),

    CONSTRAINT CK_LOAN_TermMonths
        CHECK (TermMonths > 0),

    CONSTRAINT CK_LOAN_EndDate_StartDate
        CHECK (EndDate > StartDate),

    CONSTRAINT CK_LOAN_Status
        CHECK ([Status] IN ('Pending', 'Approved', 'Rejected', 'Paying', 'Completed', 'Overdue'))
);
GO

/*==============================================================
16. LOAN_PAYMENT
==============================================================*/
CREATE TABLE dbo.LOAN_PAYMENT
(
    LoanPaymentID     BIGINT IDENTITY(1,1) NOT NULL,
    LoanID            INT NOT NULL,
    PaymentDate       DATETIME NOT NULL
        CONSTRAINT DF_LOAN_PAYMENT_PaymentDate DEFAULT (GETDATE()),
    AmountPaid        DECIMAL(18,2) NOT NULL,
    PrincipalPaid     DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_LOAN_PAYMENT_PrincipalPaid DEFAULT (0),
    InterestPaid      DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_LOAN_PAYMENT_InterestPaid DEFAULT (0),
    PenaltyFee        DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_LOAN_PAYMENT_PenaltyFee DEFAULT (0),
    PaymentChannel    VARCHAR(20) NOT NULL,
    EmployeeID        INT NULL,
    Note              NVARCHAR(255) NULL,

    CONSTRAINT PK_LOAN_PAYMENT PRIMARY KEY (LoanPaymentID),

    CONSTRAINT FK_LOAN_PAYMENT_LOAN
        FOREIGN KEY (LoanID) REFERENCES dbo.LOAN(LoanID),

    CONSTRAINT FK_LOAN_PAYMENT_EMPLOYEE
        FOREIGN KEY (EmployeeID) REFERENCES dbo.EMPLOYEE(EmployeeID),

    CONSTRAINT CK_LOAN_PAYMENT_AmountPaid
        CHECK (AmountPaid > 0),

    CONSTRAINT CK_LOAN_PAYMENT_PrincipalPaid
        CHECK (PrincipalPaid >= 0),

    CONSTRAINT CK_LOAN_PAYMENT_InterestPaid
        CHECK (InterestPaid >= 0),

    CONSTRAINT CK_LOAN_PAYMENT_PenaltyFee
        CHECK (PenaltyFee >= 0),

    CONSTRAINT CK_LOAN_PAYMENT_AmountFormula
        CHECK (AmountPaid = PrincipalPaid + InterestPaid + PenaltyFee),

    CONSTRAINT CK_LOAN_PAYMENT_PaymentChannel
        CHECK (PaymentChannel IN ('Counter', 'InternetBanking', 'MobileBanking', 'ATM', 'System')),

    CONSTRAINT CK_LOAN_PAYMENT_EmployeeRule
        CHECK (
            (PaymentChannel = 'Counter' AND EmployeeID IS NOT NULL)
            OR
            (PaymentChannel IN ('InternetBanking', 'MobileBanking', 'ATM', 'System') AND EmployeeID IS NULL)
        )
);
GO