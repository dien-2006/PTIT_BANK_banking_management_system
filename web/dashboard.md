xây dụng hoàn thiện mục dashboah cho dự án PTIT BANK
1Biểu đồ số lượng giao dịch theo tháng
- nguồn: vw_TransactionDetail
- nhóm theo tháng từ TransactionDate

2. Biểu đồ tổng giá trị giao dịch theo tháng
- nguồn: vw_TransactionDetail
- sum Amount theo tháng

3. Biểu đồ cơ cấu giao dịch theo loại
- nguồn: vw_TransactionDetail
- nhóm theo TransactionTypeName

4. Biểu đồ giao dịch theo kênh
- nguồn: vw_TransactionDetail
- nhóm theo Channel
- các kênh hợp lệ: Counter, InternetBanking, MobileBanking, ATM, System

5. Biểu đồ dư nợ theo loại khoản vay
- nguồn: vw_LoanStatus
- nhóm theo LoanTypeName
- dùng RemainingPrincipal
YÊU CẦU THIẾT KẾ UI
- Giao diện dark hoặc light hiện đại, chuyên nghiệp kiểu ngân hàng
- Có sidebar bên trái
- Có topbar
- Responsive vừa đủ cho desktop
- KPI card có icon
- Chart card bo góc, shadow nhẹ
- Màu sắc nghiêm túc, thiên về ngân hàng / enterprise
- Không dùng style lòe loẹt
- Có loading state, empty state, error state