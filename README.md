# PTIT BANK Banking Management System

Hệ thống quản lý ngân hàng cho bài tập lớn PTIT, gồm:

- Frontend: `React + TypeScript + Tailwind CSS`
- Backend: `Node.js + Express + TypeScript`
- Database: `SQL Server`

Luồng tổng thể của hệ thống:

```text
Người dùng -> Frontend -> Backend API -> SQL Server
```

Backend đóng vai trò nhận request, kiểm tra dữ liệu đầu vào, phân quyền, rồi gọi trực tiếp `stored procedure`, `view`, `function` hoặc `query` trong SQL Server. Logic nghiệp vụ trọng tâm được đặt ở database.

## 1. Giới thiệu

Hệ thống phục vụ các nghiệp vụ cơ bản của ngân hàng:

- Quản lý khách hàng
- Mở và theo dõi tài khoản ngân hàng
- Nạp, rút, chuyển tiền
- Phát hành thẻ
- Quản lý khoản vay và thanh toán khoản vay
- Theo dõi dashboard, báo cáo và hiệu suất chi nhánh
- Đăng nhập hệ thống cho nhân viên và đăng nhập online cho khách hàng

Mục tiêu của repo:

- Xây dựng một mô hình dữ liệu ngân hàng tương đối đầy đủ
- Đưa nghiệp vụ chính xuống SQL Server bằng procedure, function, trigger
- Cung cấp web app để demo trực tiếp các thao tác nghiệp vụ

## 2. Cấu trúc thư mục

```text
.
|-- README.md
|-- banking_dataset/
|-- web/
|   |-- backend/
|   |   `-- src/
|   |       |-- config/
|   |       |-- controllers/
|   |       |-- middleware/
|   |       |-- repositories/
|   |       |-- routes/
|   |       |-- services/
|   |       `-- utils/
|   |-- frontend/
|   |   `-- src/
|   |       |-- api/
|   |       |-- components/
|   |       |-- pages/
|   |       |-- types/
|   |       `-- utils/
|   |-- sql_rebuild/
|   |   |-- 00_seed_reference_data.sql
|   |   |-- 01_functions.sql
|   |   |-- 02_procedures.sql
|   |   |-- 03_triggers.sql
|   |   |-- 04_views.sql
|   |   `-- 05_query_and_dashboard_procedures.sql
|   |-- create_table.sql
|   |-- sql.sql
|   `-- .env.example
```

## 3. Thiết kế cơ sở dữ liệu

File tạo schema chính:

- [web/create_table.sql](E:/PTIT_BANK_banking_management_system/web/create_table.sql:1)

### 3.1 Danh sách bảng

Hệ thống hiện có 15 bảng chính:

1. `BRANCH`: thông tin chi nhánh
2. `ROLE`: vai trò nhân viên
3. `EMPLOYEE`: hồ sơ nhân viên
4. `SYSTEM_USER`: tài khoản đăng nhập nội bộ
5. `CUSTOMER`: hồ sơ khách hàng
6. `CUSTOMER_ONLINE_ACCOUNT`: tài khoản online của khách hàng
7. `ACCOUNT_TYPE`: loại tài khoản ngân hàng
8. `BANK_ACCOUNT`: tài khoản ngân hàng
9. `CARD`: thẻ ngân hàng
10. `ACCOUNT_STATUS_HISTORY`: lịch sử đổi trạng thái tài khoản
11. `TRANSACTION_TYPE`: loại giao dịch
12. `BANK_TRANSACTION`: giao dịch ngân hàng
13. `LOAN_TYPE`: loại khoản vay
14. `LOAN`: khoản vay
15. `LOAN_PAYMENT`: các lần thanh toán khoản vay

### 3.2 Vai trò từng nhóm bảng

`Danh mục và tổ chức`

- `BRANCH`
- `ROLE`
- `ACCOUNT_TYPE`
- `TRANSACTION_TYPE`
- `LOAN_TYPE`

`Người dùng hệ thống`

- `EMPLOYEE`
- `SYSTEM_USER`

`Khách hàng`

- `CUSTOMER`
- `CUSTOMER_ONLINE_ACCOUNT`

`Tài khoản và thẻ`

- `BANK_ACCOUNT`
- `CARD`
- `ACCOUNT_STATUS_HISTORY`

`Giao dịch`

- `BANK_TRANSACTION`

`Khoản vay`

- `LOAN`
- `LOAN_PAYMENT`

### 3.3 Quan hệ dữ liệu chính

- Một `BRANCH` có nhiều `EMPLOYEE` và nhiều `BANK_ACCOUNT`
- Một `ROLE` có nhiều `EMPLOYEE`
- Một `EMPLOYEE` có thể có một `SYSTEM_USER`
- Một `CUSTOMER` có thể có nhiều `BANK_ACCOUNT`
- Một `CUSTOMER` có thể có tối đa một `CUSTOMER_ONLINE_ACCOUNT`
- Một `BANK_ACCOUNT` thuộc về một `CUSTOMER`, một `BRANCH` và một `ACCOUNT_TYPE`
- Một `BANK_ACCOUNT` có thể có nhiều `CARD`
- Một `BANK_ACCOUNT` có nhiều bản ghi trong `ACCOUNT_STATUS_HISTORY`
- Một `BANK_TRANSACTION` tham chiếu tài khoản nguồn, tài khoản đích và có thể gắn với `EMPLOYEE`
- Một `LOAN` thuộc về `CUSTOMER`, `BRANCH`, `EMPLOYEE`, `LOAN_TYPE`
- Một `LOAN` có nhiều `LOAN_PAYMENT`

### 3.4 Ràng buộc dữ liệu nổi bật

- `CUSTOMER.Gender` chỉ nhận `Male`, `Female`, `Other`
- `BANK_ACCOUNT.Status` chỉ nhận `Active`, `Inactive`, `Blocked`, `Closed`
- `BANK_ACCOUNT.Currency` chỉ nhận `VND`, `USD`, `EUR`
- `BANK_TRANSACTION.Amount > 0`
- `BANK_TRANSACTION` bắt buộc có ít nhất tài khoản nguồn hoặc đích
- `ACCOUNT_STATUS_HISTORY` kiểm tra `OldStatus <> NewStatus`
- `LOAN_PAYMENT.AmountPaid` được ghi đầy đủ theo từng lần thanh toán

## 4. Chức năng chính của hệ thống

### 4.1 Xác thực

- Đăng nhập hệ thống cho nhân viên
- Đăng nhập online cho khách hàng
- Phân quyền theo vai trò qua JWT

### 4.2 Khách hàng

- Thêm khách hàng mới
- Tìm kiếm và xem danh sách khách hàng
- Đăng ký tài khoản online cho khách hàng
- Xem tổng số tài khoản và tổng số dư của khách hàng

### 4.3 Tài khoản ngân hàng

- Mở tài khoản mới
- Tự sinh `AccountNumber`
- Xem danh sách tài khoản
- Xem số dư, trạng thái hoạt động và giao dịch gần đây
- Cập nhật trạng thái tài khoản

### 4.4 Giao dịch

- Nạp tiền
- Rút tiền
- Chuyển tiền
- Tra cứu lịch sử giao dịch theo tài khoản và thời gian

### 4.5 Thẻ ngân hàng

- Phát hành thẻ cho tài khoản đang hoạt động
- Đồng bộ trạng thái thẻ khi tài khoản bị khóa hoặc đóng

### 4.6 Khoản vay

- Tạo khoản vay mới
- Thanh toán khoản vay
- Tính dư nợ gốc còn lại
- Cập nhật trạng thái khoản vay hoàn thành hoặc quá hạn

### 4.7 Dashboard và báo cáo

- Tổng quan số khách hàng, số tài khoản, số giao dịch trong ngày
- Top khách hàng theo tổng số dư
- Top chi nhánh theo doanh số giao dịch
- Báo cáo khoản vay quá hạn
- Báo cáo hiệu suất nhân viên

## 5. Function, Procedure, View, Trigger

Các object SQL được tách riêng trong thư mục [web/sql_rebuild](E:/PTIT_BANK_banking_management_system/web/sql_rebuild:1).

### 5.1 Function

File: [01_functions.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/01_functions.sql:1)

`dbo.fn_GetCustomerTotalBalance(@CustomerID)`

- Tính tổng số dư tất cả tài khoản chưa đóng của một khách hàng
- Được dùng trong dashboard, top customer và truy vấn tổng hợp

`dbo.fn_GetLoanRemainingPrincipal(@LoanID)`

- Tính dư nợ gốc còn lại của khoản vay
- Được dùng khi thanh toán khoản vay, view khoản vay và báo cáo overdue

### 5.2 Stored Procedure nghiệp vụ

File: [02_procedures.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/02_procedures.sql:1)

`Khách hàng`

- `sp_AddCustomer`: thêm khách hàng, kiểm tra trùng `NationalID`, `Phone`, `Email`, sinh `CustomerCode`
- `sp_SearchCustomer`: tìm khách hàng theo mã, tên, CCCD, số điện thoại, email

`Tài khoản ngân hàng`

- `sp_OpenBankAccount`: mở tài khoản, kiểm tra khách hàng, chi nhánh, loại tài khoản, `MinBalance`, sinh `AccountNumber`
- `sp_UpdateBankAccountStatus`: đổi trạng thái tài khoản, chặn đóng tài khoản còn số dư, đẩy metadata vào `SESSION_CONTEXT` cho trigger

`Giao dịch`

- `sp_DepositMoney`: nạp tiền, cập nhật số dư, ghi `BANK_TRANSACTION`
- `sp_WithdrawMoney`: rút tiền, kiểm tra số dư, ghi `BANK_TRANSACTION`
- `sp_TransferMoney`: chuyển tiền, dùng transaction SQL để trừ và cộng tiền an toàn
- `sp_GetTransactionHistory`: lấy lịch sử giao dịch theo tài khoản và khoảng thời gian

`Tài khoản online khách hàng`

- `sp_RegisterCustomerOnlineAccount`: tạo tài khoản online cho khách hàng
- `sp_UpdateCustomerOnlineAccountStatus`: khóa hoặc mở khóa tài khoản online
- `sp_CustomerOnlineLogin`: đăng nhập online cho khách hàng

`Thẻ`

- `sp_IssueCard`: phát hành thẻ mới cho tài khoản đang active

`Khoản vay`

- `sp_CreateLoan`: tạo khoản vay sau khi kiểm tra khách hàng, nhân viên, chi nhánh, loại vay
- `sp_PayLoanInstallment`: ghi nhận thanh toán khoản vay, cập nhật trạng thái khoản vay
- `sp_UpdateOverdueLoans`: cập nhật các khoản vay quá hạn

`Hệ thống nội bộ`

- `sp_SystemUserLogin`: đăng nhập cho nhân viên
- `sp_CreateSystemUser`: cấp tài khoản hệ thống cho nhân viên

### 5.3 Stored Procedure đọc dữ liệu và dashboard

File: [05_query_and_dashboard_procedures.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/05_query_and_dashboard_procedures.sql:1)

- `sp_GetDashboardOverview`
- `sp_GetTopCustomers`
- `sp_GetTopBranches`
- `sp_GetCustomerSummary`
- `sp_GetAccountSummary`
- `sp_GetCardSummary`
- `sp_GetLoanSummary`
- `sp_GetBranches`
- `sp_GetAccountTypes`
- `sp_GetLoanTypes`
- `sp_GetMonthlyTransactionCount`
- `sp_GetMonthlyTransactionAmount`
- `sp_GetTransactionTypeBreakdown`
- `sp_GetTransactionChannelBreakdown`
- `sp_GetLoanOutstandingByType`
- `sp_GetOverdueLoanSummary`
- `sp_GetEmployeePerformance`

Nhóm này chủ yếu phục vụ:

- dashboard
- combobox / filter
- danh sách nghiệp vụ
- báo cáo

### 5.4 View

File: [04_views.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/04_views.sql:1)

- `vw_CustomerAccountSummary`: tổng hợp khách hàng, số tài khoản, tổng số dư
- `vw_TransactionDetail`: chi tiết hóa giao dịch để hiển thị ra màn hình
- `vw_LoanStatus`: tổng hợp trạng thái khoản vay, số tiền đã trả, dư nợ còn lại
- `vw_BranchPerformance`: hiệu suất chi nhánh
- `vw_OverdueLoans`: danh sách khoản vay quá hạn
- `vw_EmployeePerformance`: hiệu suất nhân viên

Vai trò của view:

- giảm lặp query ở backend
- gom join phức tạp về database
- phục vụ màn hình danh sách và báo cáo nhanh hơn

### 5.5 Trigger

File: [03_triggers.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/03_triggers.sql:1)

`trg_BankAccount_StatusHistory`

- chạy sau khi `BANK_ACCOUNT.Status` thay đổi
- tự ghi vào `ACCOUNT_STATUS_HISTORY`
- đọc `ChangedByType`, `ChangedEmployeeID`, `ChangedReason` từ `SESSION_CONTEXT`

`trg_BankAccount_BlockCard`

- chạy sau khi `BANK_ACCOUNT.Status` thay đổi
- nếu tài khoản `Blocked` thì thẻ active bị chuyển sang `Blocked`
- nếu tài khoản `Closed` thì thẻ active/blocked bị chuyển sang `Cancelled`

Ý nghĩa của trigger:

- đảm bảo log trạng thái luôn được ghi kể cả khi thay đổi từ nhiều luồng
- giữ dữ liệu tài khoản và thẻ đồng bộ ở tầng database

## 6. Cách tính năng gọi đến database

Luồng code phía web:

```text
Page React
-> apiRequest(...)
-> Express Route
-> Controller
-> Service
-> Repository
-> SQL Server (procedure / view / function / query)
```

### 6.1 Frontend gọi backend ở đâu

File gọi HTTP chung:

- [web/frontend/src/api/client.ts](E:/PTIT_BANK_banking_management_system/web/frontend/src/api/client.ts:1)

Mỗi màn hình React gọi `apiRequest(...)`, ví dụ:

- khách hàng: [web/frontend/src/pages/customers-page.tsx](E:/PTIT_BANK_banking_management_system/web/frontend/src/pages/customers-page.tsx:1)
- tài khoản: [web/frontend/src/pages/accounts-page.tsx](E:/PTIT_BANK_banking_management_system/web/frontend/src/pages/accounts-page.tsx:1)
- giao dịch: [web/frontend/src/pages/transactions-page.tsx](E:/PTIT_BANK_banking_management_system/web/frontend/src/pages/transactions-page.tsx:1)

### 6.2 Backend nhận request ở đâu

Khai báo route:

- [web/backend/src/routes/index.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/routes/index.ts:1)

Ví dụ:

- `POST /api/customers`
- `GET /api/accounts`
- `POST /api/accounts/open`
- `POST /api/transactions/deposit`
- `POST /api/transactions/withdraw`
- `POST /api/transactions/transfer`
- `GET /api/transactions/history`
- `POST /api/cards/issue`
- `POST /api/loans`
- `POST /api/loans/payment`

### 6.3 Controller và Service

Controller:

- [web/backend/src/controllers/banking-controller.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/controllers/banking-controller.ts:1)
- [web/backend/src/controllers/auth-controller.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/controllers/auth-controller.ts:1)

Service:

- [web/backend/src/services/banking-service.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/services/banking-service.ts:1)
- [web/backend/src/services/auth-service.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/services/auth-service.ts:1)

Controller nhận request và trả response.

Service giữ lớp trung gian.

Repository mới là nơi gọi SQL thật.

### 6.4 Repository gọi DB ở đâu

File chính:

- [web/backend/src/repositories/banking-repository.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/repositories/banking-repository.ts:1)
- [web/backend/src/repositories/auth-repository.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/repositories/auth-repository.ts:1)

Ví dụ mapping thực tế:

| Tính năng web | API | Repository | DB object |
|---|---|---|---|
| Đăng nhập nhân viên | `POST /api/auth/login` | `systemLogin()` | `sp_SystemUserLogin` |
| Đăng nhập online khách hàng | `POST /api/customers/online-login` | `customerOnlineLogin()` | `sp_CustomerOnlineLogin` |
| Tạo khách hàng | `POST /api/customers` | `addCustomer()` | `sp_AddCustomer` |
| Đăng ký online | `POST /api/customers/register-online` | `registerOnlineAccount()` | `sp_RegisterCustomerOnlineAccount` |
| Danh sách khách hàng | `GET /api/customers` | `getCustomers()` | `vw_CustomerAccountSummary` |
| Danh sách tài khoản | `GET /api/accounts` | `getAccounts()` | query join `BANK_ACCOUNT`, `CUSTOMER`, `ACCOUNT_TYPE`, `BRANCH` |
| Mở tài khoản | `POST /api/accounts/open` | `openAccount()` | `sp_OpenBankAccount` |
| Đổi trạng thái tài khoản | `PATCH /api/accounts/status` | `updateAccountStatus()` | `sp_UpdateBankAccountStatus` + trigger |
| Nạp tiền | `POST /api/transactions/deposit` | `deposit()` | `sp_DepositMoney` |
| Rút tiền | `POST /api/transactions/withdraw` | `withdraw()` | `sp_WithdrawMoney` |
| Chuyển tiền | `POST /api/transactions/transfer` | `transfer()` | `sp_TransferMoney` |
| Xem lịch sử giao dịch 1 tài khoản | `GET /api/transactions/history?AccountID=...` | `getTransactionHistory()` | `sp_GetTransactionHistory` |
| Xem lịch sử giao dịch tổng quát | `GET /api/transactions/history` | `getTransactionHistory()` | `vw_TransactionDetail` |
| Danh sách thẻ | `GET /api/cards` | `getCards()` | query `CARD` |
| Phát hành thẻ | `POST /api/cards/issue` | `issueCard()` | `sp_IssueCard` |
| Danh sách khoản vay | `GET /api/loans` | `getLoans()` | `vw_LoanStatus` |
| Tạo khoản vay | `POST /api/loans` | `createLoan()` | `sp_CreateLoan` |
| Thanh toán khoản vay | `POST /api/loans/payment` | `payLoanInstallment()` | `sp_PayLoanInstallment` |
| Dashboard tổng quan | `GET /api/dashboard` | `getDashboardOverview()` | query + `fn_GetCustomerTotalBalance` + view |

### 6.5 Vì sao backend vẫn có query trực tiếp

Repo hiện tại dùng cả hai cách:

- gọi `stored procedure`
- hoặc chạy `SELECT` trực tiếp trên `view` / bảng join

Lý do:

- procedure phù hợp cho thao tác ghi và nghiệp vụ cần kiểm tra nhiều điều kiện
- view phù hợp cho danh sách và báo cáo
- query trực tiếp phù hợp cho một số màn đơn giản, ít logic ghi

## 7. Cách chạy database

### 7.1 Tạo schema

Mở SQL Server Management Studio rồi chạy lần lượt:

1. [web/create_table.sql](E:/PTIT_BANK_banking_management_system/web/create_table.sql:1)
2. [web/sql_rebuild/00_seed_reference_data.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/00_seed_reference_data.sql:1)
3. [web/sql_rebuild/01_functions.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/01_functions.sql:1)
4. [web/sql_rebuild/02_procedures.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/02_procedures.sql:1)
5. [web/sql_rebuild/03_triggers.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/03_triggers.sql:1)
6. [web/sql_rebuild/04_views.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/04_views.sql:1)
7. [web/sql_rebuild/05_query_and_dashboard_procedures.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/05_query_and_dashboard_procedures.sql:1)

Nếu muốn dùng file gộp, có thể tham khảo:

- [web/sql.sql](E:/PTIT_BANK_banking_management_system/web/sql.sql:1)

### 7.2 Seed dữ liệu mẫu

Repo có sẵn dữ liệu tham chiếu và dataset để demo:

- `web/sql_rebuild/00_seed_reference_data.sql`
- `banking_dataset/`

## 8. Cách chạy web

### 8.1 Yêu cầu môi trường

- Node.js LTS
- npm
- SQL Server
- ODBC Driver for SQL Server

### 8.2 Cài dependencies

Tại thư mục [web](E:/PTIT_BANK_banking_management_system/web:1):

```bash
npm install
```

### 8.3 Tạo file môi trường

Tạo `.env` từ `.env.example`:

```bash
copy .env.example .env
```

Nội dung mẫu hiện có:

```env
PORT=4000
NODE_ENV=development
FRONTEND_URL=http://localhost:5173
JWT_SECRET=change-me
JWT_EXPIRES_IN=8h

DB_SERVER=localhost
DB_PORT=1433
DB_NAME=BankingManagementDB
DB_USER=sa
DB_PASSWORD=YourStrongPassword123
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true
```

File tham chiếu:

- [web/.env.example](E:/PTIT_BANK_banking_management_system/web/.env.example:1)

### 8.4 Chạy development

Tại thư mục `web`:

```bash
npm run dev
```

Script đang có:

- `dev`: chạy song song backend và frontend
- `dev:backend`
- `dev:frontend`
- `build`

File script:

- [web/package.json](E:/PTIT_BANK_banking_management_system/web/package.json:1)

### 8.5 Địa chỉ mặc định

- Frontend: `http://localhost:5173`
- Backend: `http://localhost:4000`
- Health check: `http://localhost:4000/health`

## 9. Phân quyền hiện có

Theo route backend, các vai trò chính đang được dùng là:

- `Admin`
- `Teller`
- `Loan Officer`
- `Branch Manager`

Ví dụ:

- `Admin`, `Teller`: khách hàng, tài khoản, giao dịch, thẻ
- `Admin`, `Loan Officer`: khoản vay
- `Admin`, `Branch Manager`: dashboard

## 10. Ghi chú triển khai

- Business rule chính nằm ở SQL Server, không nên viết chồng logic ở frontend
- Backend có lớp `repository` để map đúng tên tham số procedure
- Trigger là phần quan trọng của nghiệp vụ trạng thái tài khoản
- Một số màn hình hiện đang đọc trực tiếp từ `view` hoặc query tổng hợp thay vì gọi procedure đọc dữ liệu
- Nếu thay đổi schema hoặc tên procedure, cần sửa mapping trong `web/backend/src/repositories`

## 11. Tài liệu nên đọc tiếp

- [web/backend/src/routes/index.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/routes/index.ts:1)
- [web/backend/src/repositories/banking-repository.ts](E:/PTIT_BANK_banking_management_system/web/backend/src/repositories/banking-repository.ts:1)
- [web/sql_rebuild/02_procedures.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/02_procedures.sql:1)
- [web/sql_rebuild/03_triggers.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/03_triggers.sql:1)
- [web/sql_rebuild/04_views.sql](E:/PTIT_BANK_banking_management_system/web/sql_rebuild/04_views.sql:1)
