import { Activity, CreditCard, Users, Wallet } from "lucide-react";
import { DongIcon } from "../components/ui/dong-icon";
import { Panel } from "../components/ui/panel";
import { StatCard } from "../components/ui/stat-card";
import { formatCurrency } from "../utils/currency";

type DashboardPageProps = {
  data: {
    overview?: Record<string, number>;
    topCustomers: Array<Record<string, unknown>>;
    topBranches: Array<Record<string, unknown>>;
  };
};

export function DashboardPage({ data }: DashboardPageProps) {
  const overview = data.overview ?? {};
  const topBranch = data.topBranches[0];
  const topBranchName = String(topBranch?.BranchName ?? "Chưa có dữ liệu");
  const topBranchId = String(topBranch?.BranchID ?? "--");
  const topBranchAccounts = Number(topBranch?.TotalAccounts ?? 0);

  return (
    <div className="grid h-full min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-4">
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
        <StatCard label="Khách hàng" value={String(overview.totalCustomers ?? 0)} icon={Users} tone="bg-red-100 text-brand-red" />
        <StatCard label="Tài khoản" value={String(overview.totalAccounts ?? 0)} icon={Wallet} tone="bg-yellow-100 text-yellow-700" />
        <StatCard label="Giao dịch hôm nay" value={String(overview.transactionsToday ?? 0)} icon={Activity} tone="bg-amber-100 text-amber-700" />
        <StatCard label="Tổng số dư" value={formatCurrency(overview.totalBalance)} icon={DongIcon} tone="bg-rose-100 text-rose-700" />
        <StatCard label="Khoản vay quá hạn" value={String(overview.overdueLoans ?? 0)} icon={CreditCard} tone="bg-orange-100 text-orange-700" />
      </div>

      <Panel className="grid min-h-0 gap-5 px-5 py-5 lg:grid-cols-[1.18fr_0.82fr]">
        <div className="flex min-h-0 flex-col">
          <p className="text-xs uppercase tracking-[0.24em] text-brand-red">Nhịp vận hành</p>
          <h2 className="mt-1 font-display text-[2rem] leading-tight text-brand-ink">Toàn cảnh hiệu suất chi nhánh</h2>
          <div className="mt-4 flex-1 rounded-[24px] bg-[linear-gradient(180deg,rgba(165,29,45,0.08),rgba(214,165,65,0.22))] px-5 py-4">
            <div className="flex h-full items-end gap-4">
              {[48, 65, 72, 54, 88, 70, 93].map((value, index) => (
                <div key={index} className="flex-1">
                  <div className="rounded-t-[16px] bg-brand-red/90 transition-all duration-500" style={{ height: `${value * 1.15}px` }} />
                  <p className="mt-2 text-center text-xs text-brand-ink/60">Ngày {index + 1}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="flex min-h-0 flex-col rounded-[24px] bg-brand-red px-6 py-5 text-white">
          <p className="text-xs uppercase tracking-[0.24em] text-white/70">Top chi nhánh</p>
          <h3 className="mt-3 font-display text-[2rem] leading-tight">Chi nhánh có doanh số nổi bật nhất hiện tại</h3>

          <div className="mt-5 rounded-[22px] bg-white/10 px-4 py-4 backdrop-blur">
            <p className="text-xs uppercase tracking-[0.18em] text-white/65">Tên chi nhánh</p>
            <p className="mt-2 font-display text-[1.9rem] leading-tight">{topBranchName}</p>

            <div className="mt-5 grid gap-3 sm:grid-cols-2">
              <div className="rounded-2xl bg-white/10 px-4 py-3">
                <p className="text-xs uppercase tracking-[0.16em] text-white/65">Mã chi nhánh</p>
                <p className="mt-2 text-lg font-semibold">{topBranchId}</p>
              </div>
              <div className="rounded-2xl bg-white/10 px-4 py-3">
                <p className="text-xs uppercase tracking-[0.16em] text-white/65">Quy mô tài khoản</p>
                <p className="mt-2 text-lg font-semibold">{Intl.NumberFormat("vi-VN").format(topBranchAccounts)}</p>
              </div>
            </div>
          </div>

          <p className="mt-5 text-sm leading-7 text-white/85">
            Khung này hiển thị chi nhánh đang dẫn đầu theo dữ liệu tổng hợp hiện có để bộ phận điều hành theo dõi nhanh hiệu suất toàn hệ thống.
          </p>
        </div>
      </Panel>
    </div>
  );
}
