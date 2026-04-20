import type { FormEvent } from "react";
import { useEffect, useMemo, useState } from "react";
import { Eye, Plus, Search, X } from "lucide-react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";
import { formatCurrency } from "../utils/currency";

type AccountsPageProps = {
  token: string;
  rows: Array<Record<string, unknown>>;
  onRefresh: () => Promise<void>;
};

type AccountRow = {
  AccountID?: number | string;
  AccountNumber?: string;
  FullName?: string;
  AccountTypeName?: string;
  BranchName?: string;
  Balance?: number | string;
  Status?: string;
  Currency?: string;
};

type TransactionRow = {
  TransactionID?: number | string;
  TransactionType?: string;
  TransactionTypeName?: string;
  Amount?: number | string;
  Description?: string;
  TransactionDate?: string;
};

type AccountTypeRow = {
  AccountTypeID: number | string;
  AccountTypeName?: string;
  MinBalance?: number | string;
};

type BranchRow = {
  BranchID: number | string;
  BranchCode?: string;
  BranchName?: string;
};

type FormField = {
  name: string;
  label: string;
  type?: string;
  placeholder?: string;
};

const formFields: FormField[] = [
  { name: "CustomerID", label: "Mã khách hàng", type: "number" },
  { name: "AccountTypeID", label: "Loại tài khoản", type: "number" },
  { name: "BranchID", label: "Chi nhánh", type: "number" },
  { name: "InitialDeposit", label: "Số tiền nộp ban đầu (VNĐ)", type: "number" },
  { name: "Currency", label: "Đơn vị tiền", placeholder: "VND" }
];

const PAGE_SIZE = 7;
const currencyOptions = ["VND", "USD", "EUR"];

function getStatusTone(status: string) {
  switch (status) {
    case "Active":
      return "bg-emerald-50 text-emerald-700";
    case "Blocked":
      return "bg-amber-50 text-amber-700";
    case "Inactive":
      return "bg-slate-100 text-slate-700";
    default:
      return "bg-rose-50 text-rose-700";
  }
}

function getStatusDescription(status: string) {
  switch (status) {
    case "Active":
      return "Tài khoản đang hoạt động bình thường và có thể giao dịch.";
    case "Blocked":
      return "Tài khoản đang bị khóa, cần kiểm tra trước khi thực hiện giao dịch.";
    case "Inactive":
      return "Tài khoản đang tạm ngưng hoạt động.";
    case "Closed":
      return "Tài khoản đã đóng và không còn khả năng giao dịch.";
    default:
      return "Chưa có mô tả trạng thái cho tài khoản này.";
  }
}

function formatDateTime(value: string | undefined) {
  if (!value) {
    return "--";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("vi-VN", {
    dateStyle: "short",
    timeStyle: "short"
  }).format(date);
}

export function AccountsPage({ token, rows, onRefresh }: AccountsPageProps) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [selectedAccount, setSelectedAccount] = useState<AccountRow | null>(null);
  const [activityRows, setActivityRows] = useState<TransactionRow[]>([]);
  const [activityLoading, setActivityLoading] = useState(false);
  const [activityError, setActivityError] = useState<string | null>(null);
  const [accountTypes, setAccountTypes] = useState<AccountTypeRow[]>([]);
  const [accountTypesLoading, setAccountTypesLoading] = useState(false);
  const [branches, setBranches] = useState<BranchRow[]>([]);
  const [branchesLoading, setBranchesLoading] = useState(false);
  const [formData, setFormData] = useState<Record<string, string>>({ Currency: "VND" });
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const filteredRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
      return rows;
    }

    return rows.filter((row) =>
      ["AccountID", "AccountNumber", "FullName", "AccountTypeName", "Status"].some((key) =>
        String(row[key] ?? "")
          .toLowerCase()
          .includes(normalized)
      )
    );
  }, [query, rows]);

  const totalPages = Math.max(1, Math.ceil(filteredRows.length / PAGE_SIZE));
  const pageRows = filteredRows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  useEffect(() => {
    let isCancelled = false;

    const loadReferenceData = async () => {
      setAccountTypesLoading(true);
      setBranchesLoading(true);

      try {
        const [accountTypeResponse, branchResponse] = await Promise.all([
          apiRequest<AccountTypeRow[]>("/api/account-types", { token }),
          apiRequest<BranchRow[]>("/api/branches", { token })
        ]);

        if (!isCancelled) {
          setAccountTypes(accountTypeResponse);
          setBranches(branchResponse);
        }
      } catch (requestError) {
        if (!isCancelled) {
          setError(requestError instanceof Error ? requestError.message : "Không thể tải dữ liệu biểu mẫu");
        }
      } finally {
        if (!isCancelled) {
          setAccountTypesLoading(false);
          setBranchesLoading(false);
        }
      }
    };

    void loadReferenceData();

    return () => {
      isCancelled = true;
    };
  }, [token]);

  useEffect(() => {
    const accountId = selectedAccount?.AccountID;
    if (!accountId) {
      setActivityRows([]);
      setActivityError(null);
      return;
    }

    let isCancelled = false;

    const loadActivity = async () => {
      setActivityLoading(true);
      setActivityError(null);

      try {
        const response = await apiRequest<TransactionRow[]>("/api/transactions/history", {
          token,
          query: { AccountID: String(accountId) }
        });

        if (!isCancelled) {
          setActivityRows(response.slice(0, 5));
        }
      } catch (requestError) {
        if (!isCancelled) {
          setActivityRows([]);
          setActivityError(requestError instanceof Error ? requestError.message : "Không thể tải lịch sử hoạt động");
        }
      } finally {
        if (!isCancelled) {
          setActivityLoading(false);
        }
      }
    };

    void loadActivity();

    return () => {
      isCancelled = true;
    };
  }, [selectedAccount, token]);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      await apiRequest("/api/accounts/open", {
        method: "POST",
        token,
        body: formData
      });

      setFormData({});
      setIsCreateOpen(false);
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
              <p className="text-center text-lg font-semibold uppercase tracking-[0.26em] text-brand-red">Quản lý tài khoản</p>
            </div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center md:gap-4">
            <label className="flex h-12 min-w-[400px] items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-5">
              <Search className="h-4 w-4 text-brand-red" />
              <input
                className="w-full bg-transparent text-sm outline-none"
                placeholder="Tìm kiếm tài khoản..."
                value={query}
                onChange={(event) => {
                  setQuery(event.target.value);
                  setPage(1);
                }}
              />
            </label>

            <Button className="flex h-12 items-center justify-center gap-2 px-6" onClick={() => setIsCreateOpen(true)}>
              <Plus className="h-4 w-4" />
              Mở tài khoản
            </Button>
          </div>
        </Panel>

        <Panel className="grid min-h-0 grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden px-5 py-4">
          <div>
            <h3 className="font-display text-2xl text-brand-ink">Quản lý tài khoản</h3>
            <p className="mt-1 text-sm text-brand-ink/60">Tìm kiếm và theo dõi số dư, trạng thái hoạt động và giao dịch gần đây của tài khoản.</p>
          </div>

          <div className="mt-2 min-h-0 overflow-auto rounded-3xl border border-brand-red/10">
            <table className="min-w-full text-left text-sm">
              <thead className="sticky top-0 bg-white/95 backdrop-blur">
                <tr className="border-b border-brand-red/10 text-brand-ink/60">
                  <th className="px-4 py-3 font-medium">Số tài khoản</th>
                  <th className="px-4 py-3 font-medium">Khách hàng</th>
                  <th className="px-4 py-3 font-medium">Loại tài khoản</th>
                  <th className="px-4 py-3 font-medium">Số dư</th>
                  <th className="px-4 py-3 font-medium">Trạng thái</th>
                  <th className="px-4 py-3 font-medium">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.length ? (
                  pageRows.map((row, index) => {
                    const account = row as AccountRow;
                    return (
                      <tr key={index} className="border-b border-brand-red/5 last:border-0">
                        <td className="px-4 py-4 text-brand-ink">{String(account.AccountNumber ?? account.AccountID ?? "")}</td>
                        <td className="px-4 py-4 text-brand-ink">{String(account.FullName ?? "")}</td>
                        <td className="px-4 py-4 text-brand-ink">{String(account.AccountTypeName ?? "")}</td>
                        <td className="px-4 py-4 text-brand-ink">{formatCurrency(account.Balance)}</td>
                        <td className="px-4 py-4 text-brand-ink">
                          <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${getStatusTone(String(account.Status ?? ""))}`}>
                            {String(account.Status ?? "")}
                          </span>
                        </td>
                        <td className="px-4 py-4">
                          <Button
                            variant="ghost"
                            className="inline-flex items-center gap-2 border border-brand-red/10"
                            onClick={() => setSelectedAccount(account)}
                          >
                            <Eye className="h-4 w-4" />
                            Xem
                          </Button>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={6} className="px-4 py-10 text-center text-brand-ink/60">
                      Không tìm thấy tài khoản phù hợp.
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

      {isCreateOpen ? (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-brand-ink/20 p-6 backdrop-blur-sm">
          <Panel className="flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-[32px] px-6 py-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm uppercase tracking-[0.24em] text-brand-red">Mở tài khoản</p>
                <h3 className="mt-2 font-display text-3xl text-brand-ink">Tạo mới tài khoản khách hàng</h3>
              </div>
              <button
                className="rounded-2xl border border-brand-red/10 bg-white px-3 py-3 text-brand-ink transition hover:bg-brand-cream"
                onClick={() => {
                  setIsCreateOpen(false);
                  setError(null);
                }}
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form className="mt-6 flex-1 space-y-4 overflow-y-auto pr-1" onSubmit={handleSubmit}>
              <div className="grid gap-4 md:grid-cols-2">
                {formFields.map((field) => (
                  <label key={field.name} className="block space-y-2">
                    <span className="text-sm font-medium text-brand-ink">{field.label}</span>
                    {field.name === "AccountTypeID" ? (
                      <select
                        className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                        value={formData[field.name] ?? ""}
                        onChange={(event) => setFormData((current) => ({ ...current, [field.name]: event.target.value }))}
                        disabled={accountTypesLoading}
                      >
                        <option value="">{accountTypesLoading ? "Đang tải loại tài khoản..." : "Chọn loại tài khoản"}</option>
                        {accountTypes.map((accountType) => (
                          <option key={String(accountType.AccountTypeID)} value={String(accountType.AccountTypeID)}>
                            {String(accountType.AccountTypeName ?? `Loại #${accountType.AccountTypeID}`)}
                            {accountType.MinBalance != null ? ` | Số dư tối thiểu: ${formatCurrency(accountType.MinBalance)}` : ""}
                          </option>
                        ))}
                      </select>
                    ) : field.name === "BranchID" ? (
                      <select
                        className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                        value={formData[field.name] ?? ""}
                        onChange={(event) => setFormData((current) => ({ ...current, [field.name]: event.target.value }))}
                        disabled={branchesLoading}
                      >
                        <option value="">{branchesLoading ? "Đang tải chi nhánh..." : "Chọn chi nhánh"}</option>
                        {branches.map((branch) => (
                          <option key={String(branch.BranchID)} value={String(branch.BranchID)}>
                            {String(branch.BranchCode ?? `CN${branch.BranchID}`)} - {String(branch.BranchName ?? `Chi nhánh #${branch.BranchID}`)}
                          </option>
                        ))}
                      </select>
                    ) : field.name === "Currency" ? (
                      <select
                        className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                        value={formData[field.name] ?? "VND"}
                        onChange={(event) => setFormData((current) => ({ ...current, [field.name]: event.target.value }))}
                      >
                        {currencyOptions.map((currency) => (
                          <option key={currency} value={currency}>
                            {currency}
                          </option>
                        ))}
                      </select>
                    ) : (
                      <input
                        type={field.type ?? "text"}
                        className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                        placeholder={field.placeholder}
                        value={formData[field.name] ?? ""}
                        onChange={(event) => setFormData((current) => ({ ...current, [field.name]: event.target.value }))}
                      />
                    )}
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
                    setIsCreateOpen(false);
                    setError(null);
                    setFormData({ Currency: "VND" });
                  }}
                >
                  Hủy
                </Button>
                <Button type="submit" className="px-5 py-3" disabled={submitting}>
                  {submitting ? "Đang xử lý..." : "Lưu tài khoản"}
                </Button>
              </div>
            </form>
          </Panel>
        </div>
      ) : null}

      {selectedAccount ? (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-brand-ink/20 p-6 backdrop-blur-sm">
          <Panel className="flex max-h-[88vh] w-full max-w-4xl flex-col overflow-hidden rounded-[32px] px-6 py-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm uppercase tracking-[0.24em] text-brand-red">Chi tiết tài khoản</p>
                <h3 className="mt-2 font-display text-3xl text-brand-ink">Tài khoản {String(selectedAccount.AccountNumber ?? selectedAccount.AccountID ?? "--")}</h3>
              </div>
              <button
                className="rounded-2xl border border-brand-red/10 bg-white px-3 py-3 text-brand-ink transition hover:bg-brand-cream"
                onClick={() => {
                  setSelectedAccount(null);
                  setActivityError(null);
                }}
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="mt-6 grid gap-4 md:grid-cols-[1.2fr_0.8fr]">
              <div className="rounded-3xl border border-brand-red/10 bg-brand-cream/55 p-5">
                <p className="text-sm uppercase tracking-[0.22em] text-brand-red">Số dư hiện tại</p>
                <p className="mt-3 font-display text-4xl text-brand-ink">{formatCurrency(selectedAccount.Balance)}</p>
                <p className="mt-2 text-sm text-brand-ink/60">
                  Loại tiền: {String(selectedAccount.Currency ?? "VND")} | Loại tài khoản: {String(selectedAccount.AccountTypeName ?? "--")}
                </p>
              </div>

              <div className="rounded-3xl border border-brand-red/10 bg-white p-5">
                <p className="text-sm uppercase tracking-[0.22em] text-brand-red">Tình trạng hoạt động</p>
                <div className="mt-3">
                  <span className={`inline-flex rounded-full px-3 py-1 text-sm font-semibold ${getStatusTone(String(selectedAccount.Status ?? ""))}`}>
                    {String(selectedAccount.Status ?? "")}
                  </span>
                </div>
                <p className="mt-3 text-sm leading-6 text-brand-ink/70">{getStatusDescription(String(selectedAccount.Status ?? ""))}</p>
              </div>
            </div>

            <div className="mt-4 grid flex-1 gap-4 overflow-hidden md:grid-cols-[0.95fr_1.05fr]">
              <div className="rounded-3xl border border-brand-red/10 bg-white p-5">
                <h4 className="font-display text-2xl text-brand-ink">Thông tin tài khoản</h4>
                <div className="mt-4 space-y-3 text-sm text-brand-ink/80">
                  <div className="flex items-center justify-between gap-4 border-b border-brand-red/10 pb-3">
                    <span>Số tài khoản nội bộ</span>
                    <span className="font-semibold text-brand-ink">{String(selectedAccount.AccountID ?? "--")}</span>
                  </div>
                  <div className="flex items-center justify-between gap-4 border-b border-brand-red/10 pb-3">
                    <span>Số tài khoản hiển thị</span>
                    <span className="font-semibold text-brand-ink">{String(selectedAccount.AccountNumber ?? "--")}</span>
                  </div>
                  <div className="flex items-center justify-between gap-4 border-b border-brand-red/10 pb-3">
                    <span>Chủ tài khoản</span>
                    <span className="font-semibold text-brand-ink">{String(selectedAccount.FullName ?? "--")}</span>
                  </div>
                  <div className="flex items-center justify-between gap-4 border-b border-brand-red/10 pb-3">
                    <span>Chi nhánh</span>
                    <span className="font-semibold text-brand-ink">{String(selectedAccount.BranchName ?? "--")}</span>
                  </div>
                  <div className="flex items-center justify-between gap-4">
                    <span>Khả năng giao dịch</span>
                    <span className="font-semibold text-brand-ink">{selectedAccount.Status === "Active" ? "Có thể giao dịch" : "Bị hạn chế"}</span>
                  </div>
                </div>
              </div>

              <div className="flex min-h-0 flex-col rounded-3xl border border-brand-red/10 bg-white p-5">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <h4 className="font-display text-2xl text-brand-ink">Hoạt động gần đây</h4>
                    <p className="mt-1 text-sm text-brand-ink/60">5 giao dịch mới nhất của tài khoản này.</p>
                  </div>
                </div>

                <div className="mt-4 min-h-0 flex-1 overflow-auto">
                  {activityLoading ? (
                    <p className="text-sm text-brand-ink/60">Đang tải lịch sử hoạt động...</p>
                  ) : activityError ? (
                    <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{activityError}</p>
                  ) : activityRows.length ? (
                    <div className="space-y-3">
                      {activityRows.map((transaction, index) => (
                        <div key={index} className="rounded-2xl border border-brand-red/10 bg-brand-cream/50 p-4">
                          <div className="flex items-start justify-between gap-4">
                            <div>
                              <p className="font-semibold text-brand-ink">
                                {String(transaction.TransactionType ?? transaction.TransactionTypeName ?? "Giao dịch")}
                              </p>
                              <p className="mt-1 text-sm text-brand-ink/60">{formatDateTime(transaction.TransactionDate)}</p>
                            </div>
                            <p className="text-sm font-semibold text-brand-ink">{formatCurrency(transaction.Amount)}</p>
                          </div>
                          <p className="mt-2 text-sm text-brand-ink/70">{String(transaction.Description ?? "Không có nội dung giao dịch")}</p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-brand-ink/60">Chưa có giao dịch nào cho tài khoản này.</p>
                  )}
                </div>
              </div>
            </div>
          </Panel>
        </div>
      ) : null}
    </>
  );
}
