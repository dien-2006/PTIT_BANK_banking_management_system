# PTIT BANK

Website fullstack cho `PTIT BANK`, bám theo yêu cầu:

- Frontend: `React + TypeScript + Tailwind CSS`
- Backend: `Node.js + Express + TypeScript`
- Database: `SQL Server`
- Logic nghiep vu quan trong: backend chi goi `stored procedure`, `function`, `query`; khong viet lai business logic trong code

## Kien Truc

Luong he thong:

`Frontend -> Backend API -> SQL Server`

Nguyen tac backend:

- Dung dung database `BankingManagementDB`
- Khong doi ten bang/cot
- Khong viet lai logic thay cho `stored procedure`
- Trigger de SQL Server tu xu ly
- JWT authentication + role-based authorization

## Mau Giao Dien

Website su dung phong cach PTIT:

- Nen sang kem
- Nhom mau do, trang, vang
- Dashboard co KPI, chart, top customer, top branch
- Cac module co bang du lieu, search va pagination

Logo duoc dua vao frontend tai:

- `frontend/public/ptit-logo.png`

## Cau Truc Thu Muc

```text
.
|-- backend
|   |-- src
|   |   |-- config
|   |   |-- controllers
|   |   |-- middleware
|   |   |-- repositories
|   |   |-- routes
|   |   |-- services
|   |   `-- utils
|-- frontend
|   |-- public
|   `-- src
|       |-- api
|       |-- components
|       |-- pages
|       `-- types
|-- .env.example
`-- package.json
```

## Backend Da Trien Khai

### Authentication

- `POST /api/auth/login` -> `sp_SystemUserLogin`
- `POST /api/customers/online-login` -> `sp_CustomerOnlineLogin`

### Customers

- `GET /api/customers`
- `POST /api/customers` -> `sp_AddCustomer`
- `POST /api/customers/register-online` -> `sp_RegisterCustomerOnlineAccount`

### Accounts

- `GET /api/accounts`
- `GET /api/account-types`
- `POST /api/accounts/open` -> `sp_OpenBankAccount`
- `PATCH /api/accounts/status` -> `sp_UpdateBankAccountStatus`

### Transactions

- `POST /api/transactions/deposit` -> `sp_DepositMoney`
- `POST /api/transactions/withdraw` -> `sp_WithdrawMoney`
- `POST /api/transactions/transfer` -> `sp_TransferMoney`
- `GET /api/transactions/history` -> `sp_GetTransactionHistory`

### Cards

- `GET /api/cards`
- `POST /api/cards/issue` -> `sp_IssueCard`

### Loans

- `GET /api/loans`
- `GET /api/loan-types`
- `POST /api/loans` -> `sp_CreateLoan`
- `POST /api/loans/payment` -> `sp_PayLoanInstallment`

### Dashboard

- `GET /api/dashboard`
- Dung query tong hop
- Dung `fn_GetCustomerTotalBalance`
- Dung `fn_GetLoanRemainingPrincipal`

## Phan Quyen

- `Admin`: toan quyen
- `Teller`: customer, account, transaction, card
- `Loan Officer`: loan, loan payment
- `Branch Manager`: dashboard, report

## Frontend Da Trien Khai

Da co cac man:

- Login
- Dashboard
- Customer management
- Account management
- Transaction workspace: deposit, withdraw, transfer
- Card management
- Loan workspace: create loan, pay installment
- Reports

## Bien Moi Truong

Tao file `.env` tu `.env.example`:

```env
PORT=4000
NODE_ENV=development
FRONTEND_URL=http://localhost:5173
JWT_SECRET=change-me
JWT_EXPIRES_IN=8h

DB_AUTH_TYPE=windows
DB_SERVER=localhost
DB_PORT=1433
DB_INSTANCE=
DB_NAME=BankingManagementDB
DB_USER=
DB_PASSWORD=
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=true
```

### Giai thich theo Windows Authentication

Voi cau hinh nhu anh cua ban trong SQL Server Management Studio:

- `Server Name`: `localhost`
- `Authentication`: `Windows Authentication`
- `Encrypt`: `Mandatory`
- `Trust Server Certificate`: bat

Thi file `.env` phu hop la:

```env
PORT=4000
NODE_ENV=development
FRONTEND_URL=http://localhost:5173
JWT_SECRET=change-me
JWT_EXPIRES_IN=8h

DB_AUTH_TYPE=windows
DB_SERVER=localhost
DB_PORT=1433
DB_INSTANCE=
DB_NAME=BankingManagementDB
DB_USER=
DB_PASSWORD=
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=true
```

Neu SQL Server cua ban la named instance, vi du `localhost\\SQLEXPRESS`, thi dung:

```env
DB_SERVER=localhost
DB_INSTANCE=SQLEXPRESS
```

Khi da dung `DB_AUTH_TYPE=windows`, backend se ket noi bang tai khoan Windows hien tai cua may, khong dung `DB_USER` va `DB_PASSWORD`.

## Cach Chay

### 1. Cai Node.js

Can cai `Node.js` ban LTS de co `node` va `npm`.

### 2. Cai dependencies

```bash
npm install
```

### 3. Tao file `.env`

```bash
copy .env.example .env
```

Cap nhat thong tin SQL Server cho dung moi truong.

### 4. Chay dev

```bash
npm run dev
```

Mac dinh:

- Frontend: `http://localhost:5173`
- Backend: `http://localhost:4000`

## Luu Y Tich Hop SQL Server

Code backend dang duoc viet theo ten tham so phu hop voi README. Neu stored procedure thuc te cua ban dung ten tham so khac, can map lai dung ten tham so trong:

- `backend/src/repositories/auth-repository.ts`
- `backend/src/repositories/banking-repository.ts`

Day la lop quan trong nhat khi noi voi database that.

Ket noi `Windows Authentication` tren backend su dung `mssql/msnodesqlv8` theo tai lieu `node-mssql`:

- https://github.com/tediousjs/node-mssql
- https://tediousjs.github.io/node-mssql/

## Tinh Trang Hien Tai

Repo da duoc scaffold day du:

- Monorepo root
- Backend Express + TypeScript
- Frontend React + TypeScript + Tailwind
- Giao dien PTIT BANK
- API map voi stored procedure trong README

## Viec Can Lam Tiep Theo

1. Cai `Node.js` tren may neu chua co.
2. Tao `.env` va noi dung thong tin SQL Server that.
3. Doi chieu ten tham so SP/function/view voi database that.
4. Chay `npm install`.
5. Chay `npm run dev`.
