# ĐỀ tài: Hệ thống quản lý ngân hàng 
## 1. Giới thiệu
## 2. 

## 3. Thiết kế cơ sở dữ liệu
## 4. Các tính năng của hệ thống quản lý ngân hàng
### a) sp_AddCustomer: Thêm 1 tài khoản mới
Nên kiểm tra:
- CCCD (NationalID) không trùng
- Phone không trùng
- Email nếu có thì không trùng
- CustomerType hợp lệ (Individual, Business) vì bảng bạn đang có CHECK ràng buộc này.
Điểm cộng:
- Trả thông báo lỗi rõ ràng
- Tự sinh CustomerCode
### b) sp_OpenBankAccount: Mở tài khoản ngân hàng mới.
Nên kiểm tra
- khách hàng tồn tại
- chi nhánh tồn tại
- loại tài khoản tồn tại
- số dư ban đầu không nhỏ hơn MinBalance
- trạng thái mặc định Active
Điểm mạnh:
- Gắn đúng với bảng ACCOUNT_TYPE, BANK_ACCOUNT, CUSTOMER, BRANCH
### c) sp_DepositMoney: Nạp tiền
Nên làm
- kiểm tra tài khoản tồn tại
- tài khoản phải Active
- số tiền > 0
- cập nhật BANK_ACCOUNT.Balance
- insert vào BANK_TRANSACTION
Điểm cộng
- cho phép chọn Channel: Counter, ATM, InternetBanking...
- nếu Counter thì yêu cầu EmployeeID, đúng với CHECK hiện tại của bảng BANK_TRANSACTION.
### d) sp_WithdrawMoney: Rút tiền
Nên kiểm tra
- tài khoản tồn tại và Active
- số dư đủ
- số dư sau rút không thấp hơn mức tối thiểu nếu bạn muốn - nâng cấp nghiệp vụ
- insert lịch sử giao dịch
### e) sp_TransferMoney : Chuyển tiền
- kiểm tra tài khoản nguồn và đích tồn tại
- không được trùng nhau
- cả hai tài khoản phải Active
- số dư nguồn đủ
- BEGIN TRANSACTION
- trừ tiền tài khoản nguồn
- cộng tiền tài khoản đích
- insert một dòng vào BANK_TRANSACTION
- COMMIT; lỗi thì ROLLBACK
### f) sp_BlockAccount: Khóa tài khoản.
Nên làm
- đổi BANK_ACCOUNT.Status
- bắt buộc truyền Reason
- ghi vào ACCOUNT_STATUS_HISTORY
Điểm mạnh:
- Rất hợp với thiết kế hiện tại có ACCOUNT_STATUS_HISTORY(OldStatus, NewStatus, ChangedByType, EmployeeID, Reason).

### g) sp_ChangeAccountStatus: Tổng quát hơn sp_BlockAccount.
Cho phép đổi:
- Active
- Inactive
- Blocked
- Closed
Hay hơn vì tái sử dụng tốt, có thể dùng cho nhiều nghiệp vụ.
### h) sp_CreateLoan: Tạo khoản vay.
Nên kiểm tra
- khách hàng tồn tại
- loại khoản vay tồn tại
- số tiền vay không vượt MaxAmount
- kỳ hạn không vượt MaxTermMonths
- lãi suất hợp lệ
- ngày kết thúc > ngày bắt đầu
- trạng thái ban đầu Pending hoặc Approved
### i) sp_ApproveLoan: Duyệt khoản vay.
Nên làm
- hỉ duyệt nếu đang Pending
- cập nhật Status = Approved hoặc Paying
- có thể giải ngân vào tài khoản ngân hàng nếu bạn muốn nâng tầm
### j) sp_PayLoanInstallment: Thanh toán khoản vay.
Nên làm
- kiểm tra khoản vay tồn tại
- khoản vay phải đang Approved, Paying, hoặc Overdue
tính phần gốc, lãi, phạt
- insert LOAN_PAYMENT
- cập nhật trạng thái khoản vay nếu đã trả xong
Vì sao ăn điểm:
- Bảng LOAN_PAYMENT của bạn đã có cấu trúc rất hợp lý: AmountPaid = PrincipalPaid + InterestPaid + PenaltyFee. Chỉ cần khai thác đúng là rất đẹp.

### k) sp_GetTransactionHistoryByAccount: Lấy lịch sử giao dịch theo tài khoản và khoảng ngày.
- Rất nên có vì dễ demo giao diện và dễ hỏi đáp lúc bảo vệ.
### l) sp_SearchCustomer
Tìm khách hàng theo:
- tên
- CCCD
- số điện thoại
- mã khách hàng
### m) fn_GetCustomerTotalBalance(@CustomerID): Trả về tổng số dư của tất cả tài khoản một khách hàng.
Rất hợp
dùng trong view
dùng trong query top khách hàng
dùng trong dashboard
### n) fn_CountCustomerAccounts(@CustomerID): Đếm số tài khoản của khách hàng.
### o) fn_CalculateLoanPaidAmount(@LoanID): Tổng số tiền khách hàng đã trả cho khoản vay.
Tính từ LOAN_PAYMENT.
### p) fn_CalculateRemainingLoan(@LoanID)
Tính số dư nợ còn lại.
Có thể tính kiểu cơ bản:
PrincipalAmount - SUM(PrincipalPaid)'

## 5. Các câu lệnh query


1. Nhóm tính năng quản lý danh mục
Đây là phần nền của hệ thống, dùng để khai báo dữ liệu chuẩn.
Nên có:
Quản lý chi nhánh BRANCH
Quản lý chức vụ nhân viên ROLE
Quản lý loại tài khoản ACCOUNT_TYPE
Quản lý loại giao dịch TRANSACTION_TYPE
Quản lý loại khoản vay LOAN_TYPE
Chức năng cụ thể:
thêm / sửa / khóa danh mục
tìm kiếm theo mã, tên
lọc theo trạng thái
kiểm tra trùng mã, trùng tên
chỉ cho phép dùng các danh mục đang hoạt động
2. Nhóm tính năng quản lý nhân viên và người dùng hệ thống
DB của bạn đã có EMPLOYEE và SYSTEM_USER nên nên tách rõ 2 lớp: hồ sơ nhân viên và tài khoản đăng nhập.
Nên có:
Thêm nhân viên mới
Cập nhật hồ sơ nhân viên
Chuyển nhân viên sang chi nhánh khác
Tạm ngưng / nghỉ việc
Tạo tài khoản đăng nhập cho nhân viên
Khóa / mở khóa tài khoản hệ thống
Đăng nhập và lưu lần đăng nhập cuối
Nâng điểm thêm:
phân quyền theo role
chỉ nhân viên giao dịch mới được xử lý giao dịch quầy
chỉ nhân viên tín dụng mới được tạo khoản vay
3. Nhóm tính năng quản lý khách hàng
DB của bạn có CUSTOMER và cả CUSTOMER_ONLINE_ACCOUNT, đây là điểm rất tốt vì cho phép tách khách hàng giao dịch tại quầy và khách hàng có tài khoản online.
Nên có:
thêm khách hàng cá nhân / doanh nghiệp
cập nhật CCCD, SĐT, email, nghề nghiệp
tra cứu khách hàng theo mã, CCCD, số điện thoại, họ tên
khóa / mở trạng thái khách hàng
tạo tài khoản online cho khách hàng
khóa / mở internet banking
xem toàn bộ tài khoản ngân hàng khách hàng đang sở hữu
xem lịch sử giao dịch và khoản vay của khách hàng
4. Nhóm tính năng quản lý tài khoản ngân hàng
Phần trung tâm của hệ thống là BANK_ACCOUNT. Nó liên kết trực tiếp với khách hàng, chi nhánh và loại tài khoản.
Nên có:
mở tài khoản mới
sinh số tài khoản tự động
nạp số dư ban đầu
tra cứu số dư
khóa / mở / đóng tài khoản
đổi loại trạng thái tài khoản
xem tài khoản theo khách hàng
xem tài khoản theo chi nhánh
xem tài khoản theo loại
Nâng cấp hay:
không cho đóng tài khoản nếu còn số dư
không cho khóa tài khoản khi đang có khoản vay liên kết nếu bạn muốn bổ sung rule nghiệp vụ
tự ghi lịch sử trạng thái vào ACCOUNT_STATUS_HISTORY
5. Nhóm tính năng lịch sử trạng thái tài khoản
Bảng ACCOUNT_STATUS_HISTORY của bạn thiết kế khá hay vì có ChangedByType và rule nhân viên/null rất thực tế.
Nên có:
lưu lịch sử đổi trạng thái tài khoản
ghi rõ trạng thái cũ, trạng thái mới
ghi lý do thay đổi
ghi ai thay đổi: nhân viên / khách hàng / hệ thống
xem timeline thay đổi trạng thái của từng tài khoản
6. Nhóm tính năng giao dịch ngân hàng
DB của bạn có BANK_TRANSACTION với SourceAccountID, DestinationAccountID, Channel, EmployeeID, rất phù hợp để làm giao dịch đa kênh.
Các tính năng chính:
nạp tiền
rút tiền
chuyển khoản nội bộ
thanh toán hóa đơn giả lập
sao kê giao dịch
tra cứu giao dịch theo tài khoản / ngày / loại / kênh
hủy giao dịch nếu trạng thái cho phép
xem chi tiết từng giao dịch


dbo.sp_AddCustomer(FullName, Gender, DateOfBirth, NationalID, Phone, Email, Address, OccupationCustomerType)
dbo.sp_SearchCustomer(Keyword)
dbo.sp_OpenBankAccount(CustomerID, BranchID, AccountTypeID, Currency, InitialBalance)
dbo.sp_DepositMoney(DestinationAccountID, Amount, EmployeeID, Channel, Description)
dbo.sp_WithdrawMoney(SourceAccountID, Amount, Fee, EmployeeID, Channel, Description)
dbo.sp_TransferMoney(SourceAccountID, DestinationAccountID, Amount, Fee, EmployeeID, Channel, Description)
dbo.sp_UpdateBankAccountStatus(AccountID, NewStatus, ChangedByType, EmployeeID, Reason)
dbo.sp_IssueCard(AccountID, ExpiryDate, CardType, PINHash)

