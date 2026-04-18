import type { FormEvent } from "react";
import { useMemo, useState } from "react";
import { Banknote, HandCoins, Search, X } from "lucide-react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";
import { formatCurrency } from "../utils/currency";

type LoansPageProps = {
  token: string;
  rows: Array<Record<string, unknown>>;
  onRefresh: () => Promise<void>;
};

type LoanAction = {
  key: string;
  title: string;
  endpoint: string;
  submitLabel: string;
  icon: typeof Banknote;
  fields: Array<{ name: string; label: string; type?: string; placeholder?: string }>;
};

const actions: LoanAction[] = [
  {
    key: "create-loan",
    title: "Tạo khoản vay",
    endpoint: "/api/loans",
    submitLabel: "Lưu khoản vay",
    icon: Banknote,
    fields: [
      { name: "CustomerID", label: "Mã khách hàng", type: "number" },
      { name: "LoanTypeID", label: "Mã loại vay", type: "number" },
      { name: "BranchID", label: "Mã chi nhánh", type: "number" },
      { name: "PrincipalAmount", label: "Số tiền gốc (VNĐ)", type: "number" },
      { name: "InterestRate", label: "Lãi suất", type: "number" },
      { name: "TermMonths", label: "Kỳ hạn tháng", type: "number" },
      { name: "StartDate", label: "Ngày bắt đầu", type: "date" },
      { name: "EndDate", label: "Ngày kết thúc", type: "date" }
    ]
  },
  {
    key: "loan-payment",
    title: "Thu nợ khoản vay",
    endpoint: "/api/loans/payment",
    submitLabel: "Ghi nhận thanh toán",
    icon: HandCoins,
    fields: [
      { name: "LoanID", label: "Mã khoản vay", type: "number" },
      { name: "PrincipalPaid", label: "Gốc đã trả (VNĐ)", type: "number" },
      { name: "InterestPaid", label: "Lãi đã trả (VNĐ)", type: "number" },
      { name: "PenaltyFee", label: "Phí phạt (VNĐ)", type: "number" },
      { name: "PaymentChannel", label: "Kênh thanh toán", placeholder: "Tại quầy" },
      { name: "Note", label: "Ghi chú" }
    ]
  }
];

const PAGE_SIZE = 7;

export function LoansPage({ token, rows, onRefresh }: LoansPageProps) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [activeAction, setActiveAction] = useState<LoanAction | null>(null);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const filteredRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
      return rows;
    }

    return rows.filter((row) =>
      ["LoanID", "FullName", "LoanTypeName", "Status"].some((key) =>
        String(row[key] ?? "")
          .toLowerCase()
          .includes(normalized)
      )
    );
  }, [query, rows]);

  const totalPages = Math.max(1, Math.ceil(filteredRows.length / PAGE_SIZE));
  const pageRows = filteredRows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!activeAction) {
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      await apiRequest(activeAction.endpoint, {
        method: "POST",
        token,
        body: formData
      });

      setFormData({});
      setActiveAction(null);
      await onRefresh();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Không thể xử lý yêu cầu");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <div className="grid h-full min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-4">
        <Panel className="flex min-h-[102px] flex-col gap-3 px-5 py-4 md:grid md:grid-cols-[minmax(0,1fr)_auto] md:items-center">
          <div className="flex justify-start">
            <div className="flex h-12 w-full max-w-[640px] items-center justify-center rounded-2xl bg-brand-cream px-8">
              <p className="text-center text-lg font-semibold uppercase tracking-[0.26em] text-brand-red">Quản lý khoản vay</p>
            </div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center md:gap-3">
            <label className="flex h-12 min-w-[340px] items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-5">
              <Search className="h-4 w-4 text-brand-red" />
              <input
                className="w-full bg-transparent text-sm outline-none"
                placeholder="Tìm kiếm khoản vay..."
                value={query}
                onChange={(event) => {
                  setQuery(event.target.value);
                  setPage(1);
                }}
              />
            </label>

            {actions.map((action) => {
              const ActionIcon = action.icon;
              return (
                <Button
                  key={action.key}
                  className="flex h-12 items-center justify-center gap-2 px-4"
                  onClick={() => {
                    setActiveAction(action);
                    setFormData({});
                    setError(null);
                  }}
                >
                  <ActionIcon className="h-4 w-4" />
                  {action.title}
                </Button>
              );
            })}
          </div>
        </Panel>

        <Panel className="grid min-h-0 grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden px-5 py-4">
          <div>
            <h3 className="font-display text-2xl text-brand-ink">Quản lý khoản vay</h3>
            <p className="mt-1 text-sm text-brand-ink/60">Tìm kiếm khoản vay và ghi nhận nghiệp vụ tín dụng trong cùng một khung làm việc rõ ràng.</p>
          </div>

          <div className="mt-2 min-h-0 overflow-auto rounded-3xl border border-brand-red/10">
            <table className="min-w-full text-left text-sm">
              <thead className="sticky top-0 bg-white/95 backdrop-blur">
                <tr className="border-b border-brand-red/10 text-brand-ink/60">
                  <th className="px-4 py-3 font-medium">Mã vay</th>
                  <th className="px-4 py-3 font-medium">Khách hàng</th>
                  <th className="px-4 py-3 font-medium">Loại vay</th>
                  <th className="px-4 py-3 font-medium">Gốc vay (VNĐ)</th>
                  <th className="px-4 py-3 font-medium">Còn lại (VNĐ)</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.length ? (
                  pageRows.map((row, index) => (
                    <tr key={index} className="border-b border-brand-red/5 last:border-0">
                      <td className="px-4 py-4 text-brand-ink">{String(row.LoanID ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.FullName ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.LoanTypeName ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{formatCurrency(row.PrincipalAmount as number | string | null | undefined)}</td>
                      <td className="px-4 py-4 text-brand-ink">{formatCurrency(row.RemainingPrincipal as number | string | null | undefined)}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-4 py-10 text-center text-brand-ink/60">
                      Không tìm thấy khoản vay phù hợp.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="mt-3 flex items-center justify-between text-sm text-brand-ink/60">
            <span>
              Trang {page} / {totalPages}
            </span>
            <div className="flex gap-2">
              <button
                className="rounded-xl border border-brand-red/10 px-3 py-2 disabled:opacity-50"
                disabled={page === 1}
                onClick={() => setPage((current) => Math.max(1, current - 1))}
              >
                Trước
              </button>
              <button
                className="rounded-xl border border-brand-red/10 px-3 py-2 disabled:opacity-50"
                disabled={page === totalPages}
                onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
              >
                Sau
              </button>
            </div>
          </div>
        </Panel>
      </div>

      {activeAction ? (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-brand-ink/20 p-6 backdrop-blur-sm">
          <Panel className="flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-[32px] px-6 py-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm uppercase tracking-[0.24em] text-brand-red">{activeAction.title}</p>
                <h3 className="mt-2 font-display text-3xl text-brand-ink">{activeAction.title}</h3>
              </div>
              <button
                className="rounded-2xl border border-brand-red/10 bg-white px-3 py-3 text-brand-ink transition hover:bg-brand-cream"
                onClick={() => {
                  setActiveAction(null);
                  setError(null);
                }}
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form className="mt-6 flex-1 space-y-4 overflow-y-auto pr-1" onSubmit={handleSubmit}>
              <div className="grid gap-4 md:grid-cols-2">
                {activeAction.fields.map((field) => (
                  <label key={field.name} className="block space-y-2">
                    <span className="text-sm font-medium text-brand-ink">{field.label}</span>
                    <input
                      type={field.type ?? "text"}
                      className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                      placeholder={field.placeholder}
                      value={formData[field.name] ?? ""}
                      onChange={(event) => setFormData((current) => ({ ...current, [field.name]: event.target.value }))}
                    />
                  </label>
                ))}
              </div>

              {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}

              <div className="flex justify-end gap-3 pt-2">
                <Button
                  type="button"
                  variant="ghost"
                  className="px-5 py-3"
                  onClick={() => {
                    setActiveAction(null);
                    setError(null);
                  }}
                >
                  Hủy
                </Button>
                <Button type="submit" className="px-5 py-3" disabled={submitting}>
                  {submitting ? "Đang xử lý..." : activeAction.submitLabel}
                </Button>
              </div>
            </form>
          </Panel>
        </div>
      ) : null}
    </>
  );
}
