import type { FormEvent } from "react";
import { useEffect, useMemo, useState } from "react";
import { History, Search, X } from "lucide-react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";
import { formatCurrency } from "../utils/currency";

type ReportsPageProps = {
  token: string;
  rows: Array<Record<string, unknown>>;
  onRefresh: () => Promise<void>;
};

type MetricRow = {
  label: string;
  count: number;
  amount: number;
};

function groupByKey(rows: Array<Record<string, unknown>>, key: string) {
  const map = new Map<string, MetricRow>();

  rows.forEach((row) => {
    const label = String(row[key] ?? "Khác");
    const current = map.get(label) ?? { label, count: 0, amount: 0 };
    current.count += 1;
    current.amount += Number(row.Amount ?? 0);
    map.set(label, current);
  });

  return [...map.values()].sort((a, b) => b.count - a.count);
}

function groupByMonth(rows: Array<Record<string, unknown>>) {
  const map = new Map<string, MetricRow>();

  rows.forEach((row) => {
    const date = new Date(String(row.TransactionDate ?? ""));
    if (Number.isNaN(date.getTime())) {
      return;
    }

    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    const label = `T${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`;
    const current = map.get(key) ?? { label, count: 0, amount: 0 };
    current.count += 1;
    current.amount += Number(row.Amount ?? 0);
    map.set(key, current);
  });

  return [...map.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-6)
    .map((entry) => entry[1]);
}

function Bars({
  rows,
  valueKey,
  emptyText
}: {
  rows: MetricRow[];
  valueKey: "count" | "amount";
  emptyText: string;
}) {
  if (!rows.length) {
    return (
      <div className="flex h-[220px] items-center justify-center rounded-[24px] border border-dashed border-brand-red/15 text-sm text-brand-ink/45">
        {emptyText}
      </div>
    );
  }

  const maxValue = Math.max(...rows.map((row) => row[valueKey]), 1);

  return (
    <div className="flex h-[220px] items-end gap-3 rounded-[24px] bg-[linear-gradient(180deg,rgba(165,29,45,0.04),rgba(214,165,65,0.12))] px-4 py-4">
      {rows.map((row) => (
        <div key={row.label} className="flex min-w-0 flex-1 flex-col items-center justify-end">
          <p className="mb-2 text-center text-[11px] font-semibold text-brand-ink/70">
            {valueKey === "amount"
              ? Intl.NumberFormat("vi-VN", { notation: "compact" }).format(row.amount)
              : Intl.NumberFormat("vi-VN").format(row.count)}
          </p>
          <div
            className="w-full rounded-t-[16px] bg-brand-red/90"
            style={{ height: `${Math.max((row[valueKey] / maxValue) * 130, 12)}px` }}
          />
          <p className="mt-2 text-center text-[11px] text-brand-ink/55">{row.label}</p>
        </div>
      ))}
    </div>
  );
}

function RankedList({
  rows,
  valueKey,
  emptyText
}: {
  rows: MetricRow[];
  valueKey: "count" | "amount";
  emptyText: string;
}) {
  if (!rows.length) {
    return (
      <div className="flex h-[220px] items-center justify-center rounded-[24px] border border-dashed border-brand-red/15 text-sm text-brand-ink/45">
        {emptyText}
      </div>
    );
  }

  const maxValue = Math.max(...rows.map((row) => row[valueKey]), 1);

  return (
    <div className="space-y-3 rounded-[24px] bg-[linear-gradient(180deg,rgba(165,29,45,0.04),rgba(214,165,65,0.10))] px-3.5 py-3.5">
      {rows.map((row) => {
        const percent = Math.max((row[valueKey] / maxValue) * 100, 12);
        const valueText =
          valueKey === "amount"
            ? formatCurrency(row.amount)
            : `${Intl.NumberFormat("vi-VN").format(row.count)} giao dịch`;

        return (
          <div key={row.label} className="space-y-1.5">
            <div className="flex items-center justify-between gap-3">
              <p className="min-w-0 truncate text-[11px] font-semibold leading-4 text-brand-ink">{row.label}</p>
              <p className="shrink-0 text-right text-[11px] leading-4 text-brand-ink/65">{valueText}</p>
            </div>
            <div
              style={{
                width: "100%",
                height: "14px",
                borderRadius: "9999px",
                background: "#ead7ce",
                overflow: "hidden",
                boxShadow: "inset 0 0 0 1px rgba(165,29,45,0.10)"
              }}
            >
              <div
                style={{
                  width: `${percent}%`,
                  minWidth: "18px",
                  height: "100%",
                  borderRadius: "9999px",
                  background: "linear-gradient(90deg, #a51d2d 0%, #c95e2e 58%, #d6a541 100%)"
                }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function ReportsPage({ token, rows, onRefresh }: ReportsPageProps) {
  const [query, setQuery] = useState("");
  const [reportRows, setReportRows] = useState<Array<Record<string, unknown>>>(rows);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setReportRows(rows);
  }, [rows]);

  const filteredRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
      return reportRows;
    }

    return reportRows.filter((row) =>
      ["TransactionID", "AccountID", "TransactionType", "TransactionTypeName", "Description", "Channel"].some((key) =>
        String(row[key] ?? "")
          .toLowerCase()
          .includes(normalized)
      )
    );
  }, [query, reportRows]);

  const totalTransactions = filteredRows.length;
  const totalAmount = filteredRows.reduce((sum, row) => sum + Number(row.Amount ?? 0), 0);
  const totalFees = filteredRows.reduce((sum, row) => sum + Number(row.Fee ?? 0), 0);
  const successTransactions = filteredRows.filter((row) => String(row.Status ?? "").toLowerCase() === "success").length;

  const monthlyRows = groupByMonth(filteredRows);
  const typeRows = groupByKey(filteredRows, "TransactionTypeName").slice(0, 5);
  const channelRows = groupByKey(filteredRows, "Channel").slice(0, 5);

  const handleHistorySubmit = async (event: FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      const payload = await apiRequest<Array<Record<string, unknown>>>("/api/transactions/history", {
        method: "GET",
        token,
        query: formData
      });

      setReportRows(payload);
      setIsHistoryOpen(false);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Không thể tải lịch sử giao dịch");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <div className="grid h-full min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-3">
        <Panel className="flex min-h-[84px] flex-col gap-2 px-5 py-3 md:grid md:grid-cols-[minmax(0,1fr)_auto] md:items-center">
          <div className="flex justify-start">
            <div className="flex h-11 w-[380px] items-center justify-center rounded-2xl bg-brand-cream px-8">
              <p className="text-center text-lg font-semibold uppercase tracking-[0.26em] text-brand-red">Báo cáo</p>
            </div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center md:gap-4">
            <label className="flex h-11 min-w-[400px] items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-5">
              <Search className="h-4 w-4 text-brand-red" />
              <input
                className="w-full bg-transparent text-sm outline-none"
                placeholder="Tìm kiếm lịch sử giao dịch..."
                value={query}
                onChange={(event) => setQuery(event.target.value)}
              />
            </label>

            <Button className="flex h-11 items-center justify-center gap-2 px-6" onClick={() => setIsHistoryOpen(true)}>
              <History className="h-4 w-4" />
              Lịch sử giao dịch
            </Button>
          </div>
        </Panel>

        <div className="grid min-h-0 gap-3 xl:grid-cols-[1.16fr_0.84fr]">
          <div className="grid min-h-0 gap-3">
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
              <Panel className="rounded-[24px] px-4 py-3.5">
                <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">Tổng giao dịch</p>
                <p className="mt-2 font-display text-[1.45rem] text-brand-ink">{Intl.NumberFormat("vi-VN").format(totalTransactions)}</p>
              </Panel>
              <Panel className="rounded-[24px] px-4 py-3.5">
                <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">Tổng giá trị</p>
                <p className="mt-2 font-display text-[1.45rem] leading-tight text-brand-ink">{formatCurrency(totalAmount)}</p>
              </Panel>
              <Panel className="rounded-[24px] px-4 py-3.5">
                <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">Phí giao dịch</p>
                <p className="mt-2 font-display text-[1.45rem] leading-tight text-brand-ink">{formatCurrency(totalFees)}</p>
              </Panel>
              <Panel className="rounded-[24px] px-4 py-3.5">
                <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">Giao dịch thành công</p>
                <p className="mt-2 font-display text-[1.45rem] text-brand-ink">{Intl.NumberFormat("vi-VN").format(successTransactions)}</p>
              </Panel>
            </div>

            <Panel className="flex min-h-0 flex-col rounded-[26px] px-5 py-4">
              <h3 className="font-display text-[1.6rem] leading-tight text-brand-ink">Giao dịch theo tháng</h3>
              <p className="mt-1 text-sm leading-6 text-brand-ink/55">
                Theo dõi nhịp phát sinh giao dịch theo từng tháng để nhìn xu hướng vận hành.
              </p>
              <div className="mt-3 min-h-0 flex-1">
                <Bars rows={monthlyRows} valueKey="count" emptyText="Chưa có dữ liệu giao dịch theo tháng." />
              </div>
            </Panel>
          </div>

          <div className="grid min-h-0 gap-3">
            <Panel className="flex min-h-0 flex-col rounded-[26px] px-5 py-4">
              <h3 className="font-display text-[1.4rem] leading-tight text-brand-ink">Cơ cấu theo loại giao dịch</h3>
              <p className="mt-1 text-[13px] leading-5 text-brand-ink/55">
                Phân loại giao dịch chính để nhìn nhanh cấu trúc nghiệp vụ.
              </p>
              <div className="mt-2.5 min-h-0 flex-1">
                <RankedList rows={typeRows} valueKey="count" emptyText="Chưa có dữ liệu theo loại giao dịch." />
              </div>
            </Panel>

            <Panel className="flex min-h-0 flex-col rounded-[26px] px-5 py-4">
              <h3 className="font-display text-[1.4rem] leading-tight text-brand-ink">Cơ cấu theo kênh</h3>
              <p className="mt-1 text-[13px] leading-5 text-brand-ink/55">
                Theo dõi các kênh giao dịch đang có giá trị phát sinh lớn nhất.
              </p>
              <div className="mt-2.5 min-h-0 flex-1">
                <RankedList rows={channelRows} valueKey="amount" emptyText="Chưa có dữ liệu theo kênh giao dịch." />
              </div>
            </Panel>
          </div>
        </div>
      </div>

      {isHistoryOpen ? (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-brand-ink/20 p-6 backdrop-blur-sm">
          <Panel className="flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-[32px] px-6 py-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm uppercase tracking-[0.24em] text-brand-red">Lịch sử giao dịch</p>
                <h3 className="mt-2 font-display text-3xl text-brand-ink">Bộ lọc báo cáo giao dịch</h3>
              </div>
              <button
                className="rounded-2xl border border-brand-red/10 bg-white px-3 py-3 text-brand-ink transition hover:bg-brand-cream"
                onClick={() => {
                  setIsHistoryOpen(false);
                  setError(null);
                }}
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form className="mt-6 flex-1 space-y-4 overflow-y-auto pr-1" onSubmit={handleHistorySubmit}>
              <div className="grid gap-4 md:grid-cols-3">
                <label className="block space-y-2">
                  <span className="text-sm font-medium text-brand-ink">Số tài khoản</span>
                  <input
                    type="number"
                    className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                    value={formData.AccountID ?? ""}
                    onChange={(event) => setFormData((current) => ({ ...current, AccountID: event.target.value }))}
                  />
                </label>
                <label className="block space-y-2">
                  <span className="text-sm font-medium text-brand-ink">Từ ngày</span>
                  <input
                    type="date"
                    className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                    value={formData.FromDate ?? ""}
                    onChange={(event) => setFormData((current) => ({ ...current, FromDate: event.target.value }))}
                  />
                </label>
                <label className="block space-y-2">
                  <span className="text-sm font-medium text-brand-ink">Đến ngày</span>
                  <input
                    type="date"
                    className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                    value={formData.ToDate ?? ""}
                    onChange={(event) => setFormData((current) => ({ ...current, ToDate: event.target.value }))}
                  />
                </label>
              </div>

              {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}

              <div className="flex justify-end gap-3 pt-2">
                <Button
                  type="button"
                  variant="ghost"
                  className="px-5 py-3"
                  onClick={async () => {
                    setFormData({});
                    setError(null);
                    await onRefresh();
                    setIsHistoryOpen(false);
                  }}
                >
                  Khôi phục
                </Button>
                <Button type="submit" className="px-5 py-3" disabled={submitting}>
                  {submitting ? "Đang tải..." : "Xem lịch sử giao dịch"}
                </Button>
              </div>
            </form>
          </Panel>
        </div>
      ) : null}
    </>
  );
}
