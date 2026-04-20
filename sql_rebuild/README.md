# SQL Rebuild

Bo SQL nay duoc tao moi, tach rieng khoi `sql.sql` goc.

Muc tieu:
- Dua tren schema trong `web/create_table.sql`
- Khong sua file SQL goc
- Dong bo ten `procedure`, `view`, `function` voi backend hien tai

Thu tu chay de xay dung CSDL:

1. `../create_table.sql`
2. `00_seed_reference_data.sql`
3. `01_functions.sql`
4. `04_views.sql`
5. `02_procedures.sql`
6. `05_query_and_dashboard_procedures.sql`
7. `03_triggers.sql`

Luu y:
- Neu khong seed cac bang danh muc nhu `TRANSACTION_TYPE`, `ACCOUNT_TYPE`, `LOAN_TYPE`, `BRANCH`, nhieu nghiep vu se fail du procedure dung.
- Cac procedure duoc viet de tuong thich voi code backend hien tai.
- Thu tu file trong folder khong phai thu tu chay. Hay chay theo danh sach ben tren.
