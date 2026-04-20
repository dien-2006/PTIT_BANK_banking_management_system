import type { FormEvent } from "react";
import { useMemo, useState } from "react";
import { ArrowDownLeft, ArrowLeftRight, ArrowUpRight, Search, X } from "lucide-react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";
import { formatCurrency } from "../utils/currency";

type TransactionsPageProps = {
  token: string;
  rows: Array<Record<string, unknown>>;
  onRefresh: () => Promise<void>;
};

type TransactionAction = {
  key: string;
  title: string;
  endpoint: string;
  submitLabel: string;
  icon: typeof ArrowUpRight;
  fields: Array<{ name: string; label: string; type?: string; placeholder?: string }>;
};

const actions: TransactionAction[] = [
  {
    key: "deposit",
    title: "Nạp tiền",
    endpoint: "/api/transactions/deposit",
    submitLabel: "Xác nhận nạp tiền",
    icon: ArrowUpRight,
    fields: [
      { name: "AccountID", label: "Số tài khoản", type: "text", placeholder: "Ví dụ: ACC20260421000866" },
      { name: "Amount", label: "Số tiền (VNĐ)", type: "number" },
      { name: "Description", label: "Nội dung" }
    ]
  },
  {
    key: "withdraw",
    title: "Rút tiền",
    endpoint: "/api/transactions/withdraw",
    submitLabel: "Xác nhận rút tiền",
    icon: ArrowDownLeft,
    fields: [
      { name: "AccountID", label: "Số tài khoản", type: "text", placeholder: "Ví dụ: ACC20260421000866" },
      { name: "Amount", label: "Số tiền (VNĐ)", type: "number" },
      { name: "Description", label: "Nội dung" }
    ]
  },
  {
    key: "transfer",
    title: "Chuyển khoản",
    endpoint: "/api/transactions/transfer",
    submitLabel: "Xác nhận chuyển khoản",
    icon: ArrowLeftRight,
    fields: [
      { name: "FromAccountID", label: "TK nguồn", type: "text", placeholder: "Ví dụ: 1000000000003" },
      { name: "ToAccountID", label: "TK đích", type: "text", placeholder: "Ví dụ: ACC20260421000866" },
      { name: "Amount", label: "Số tiền (VNĐ)", type: "number" },
      { name: "Description", label: "Nội dung" }
    ]
  }
];

const PAGE_SIZE = 7;

function getTransactionAccountLabel(row: Record<string, unknown>) {
  const sourceAccountNumber = row.SourceAccountNumber;
  const destinationAccountNumber = row.DestinationAccountNumber;
  const sourceAccountId = row.SourceAccountID;
  const destinationAccountId = row.DestinationAccountID;
  const transactionType = String(row.TransactionType ?? "").toLowerCase();
  const sourceLabel =
    sourceAccountNumber != null && sourceAccountNumber !== "" ? String(sourceAccountNumber) : sourceAccountId != null && sourceAccountId !== "" ? String(sourceAccountId) : "";
  const destinationLabel =
    destinationAccountNumber != null && destinationAccountNumber !== ""
      ? String(destinationAccountNumber)
      : destinationAccountId != null && destinationAccountId !== ""
        ? String(destinationAccountId)
        : "";

  if (transactionType === "transfer" && sourceLabel && destinationLabel) {
    return `${sourceLabel} -> ${destinationLabel}`;
  }

  if (sourceLabel) {
    return sourceLabel;
  }

  if (destinationLabel) {
    return destinationLabel;
  }

  if (row.AccountID != null && row.AccountID !== "") {
    return String(row.AccountID);
  }

  return "--";
}

export function TransactionsPage({ token, rows, onRefresh }: TransactionsPageProps) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [activeAction, setActiveAction] = useState<TransactionAction | null>(null);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const filteredRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
      return rows;
    }

    return rows.filter((row) =>
      [
        String(row.TransactionID ?? ""),
        String(row.AccountID ?? ""),
        String(row.SourceAccountID ?? ""),
        String(row.DestinationAccountID ?? ""),
        String(row.TransactionType ?? ""),
        String(row.Description ?? "")
      ].some((value) => value.toLowerCase().includes(normalized))
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
              <p className="text-center text-lg font-semibold uppercase tracking-[0.26em] text-brand-red">Quản lý giao dịch</p>
            </div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center md:gap-3">
            <label className="flex h-12 min-w-[340px] items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-5">
              <Search className="h-4 w-4 text-brand-red" />
              <input
                className="w-full bg-transparent text-sm outline-none"
                placeholder="Tìm kiếm giao dịch..."
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
            <h3 className="font-display text-2xl text-brand-ink">Quản lý giao dịch</h3>
            <p className="mt-1 text-sm text-brand-ink/60">Theo dõi lịch sử giao dịch và thực hiện thao tác tài chính trong cùng một khung làm việc rõ ràng.</p>
          </div>

          <div className="mt-2 min-h-0 overflow-auto rounded-3xl border border-brand-red/10">
            <table className="min-w-full text-left text-sm">
              <thead className="sticky top-0 bg-white/95 backdrop-blur">
                <tr className="border-b border-brand-red/10 text-brand-ink/60">
                  <th className="px-4 py-3 font-medium">Mã GD</th>
                  <th className="px-4 py-3 font-medium">Tài khoản</th>
                  <th className="px-4 py-3 font-medium">Loại GD</th>
                  <th className="px-4 py-3 font-medium">Số tiền (VNĐ)</th>
                  <th className="px-4 py-3 font-medium">Nội dung</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.length ? (
                  pageRows.map((row, index) => (
                    <tr key={index} className="border-b border-brand-red/5 last:border-0">
                      <td className="px-4 py-4 text-brand-ink">{String(row.TransactionID ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{getTransactionAccountLabel(row)}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.TransactionType ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{formatCurrency(row.Amount as number | string | null | undefined)}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.Description ?? "")}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-4 py-10 text-center text-brand-ink/60">
                      Không tìm thấy giao dịch phù hợp.
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
                <h3 className="mt-2 font-display text-3xl text-brand-ink">Thực hiện {activeAction.title.toLowerCase()}</h3>
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
