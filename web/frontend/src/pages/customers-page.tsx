import type { FormEvent } from "react";
import { useMemo, useState } from "react";
import { Plus, Search, X } from "lucide-react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";

type CustomersPageProps = {
  token: string;
  rows: Array<Record<string, unknown>>;
  onRefresh: () => Promise<void>;
};

const formFields: Array<{ name: string; label: string; type?: string; placeholder?: string }> = [
  { name: "FullName", label: "Họ tên" },
  { name: "DateOfBirth", label: "Ngày sinh", type: "date" },
  { name: "Gender", label: "Giới tính", placeholder: "Nam / Nữ" },
  { name: "PhoneNumber", label: "Số điện thoại" },
  { name: "Email", label: "Email", type: "email" },
  { name: "Address", label: "Địa chỉ" },
  { name: "IdentityNumber", label: "Số giấy tờ" },
  { name: "BranchID", label: "Mã chi nhánh", type: "number" }
];

const PAGE_SIZE = 7;

export function CustomersPage({ token, rows, onRefresh }: CustomersPageProps) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const filteredRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
      return rows;
    }

    return rows.filter((row) =>
      ["CustomerID", "FullName", "PhoneNumber", "Email"].some((key) =>
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
    setSubmitting(true);
    setError(null);

    try {
      await apiRequest("/api/customers", {
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
              <p className="text-center text-lg font-semibold uppercase tracking-[0.26em] text-brand-red">Quản lý khách hàng</p>
            </div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center md:gap-4">
            <label className="flex h-12 min-w-[400px] items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-5">
              <Search className="h-4 w-4 text-brand-red" />
              <input
                className="w-full bg-transparent text-sm outline-none"
                placeholder="Tìm kiếm khách hàng..."
                value={query}
                onChange={(event) => {
                  setQuery(event.target.value);
                  setPage(1);
                }}
              />
            </label>

            <Button className="flex h-12 items-center justify-center gap-2 px-6" onClick={() => setIsCreateOpen(true)}>
              <Plus className="h-4 w-4" />
              Tạo khách hàng
            </Button>
          </div>
        </Panel>

        <Panel className="grid min-h-0 grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden px-5 py-4">
          <div>
            <h3 className="font-display text-2xl text-brand-ink">Quản lý khách hàng</h3>
            <p className="mt-1 text-sm text-brand-ink/60">Tìm kiếm và theo dõi hồ sơ khách hàng trong cùng một khung làm việc rõ ràng.</p>
          </div>

          <div className="mt-2 min-h-0 overflow-auto rounded-3xl border border-brand-red/10">
            <table className="min-w-full text-left text-sm">
              <thead className="sticky top-0 bg-white/95 backdrop-blur">
                <tr className="border-b border-brand-red/10 text-brand-ink/60">
                  <th className="px-4 py-3 font-medium">Mã KH</th>
                  <th className="px-4 py-3 font-medium">Họ tên</th>
                  <th className="px-4 py-3 font-medium">Điện thoại</th>
                  <th className="px-4 py-3 font-medium">Email</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.length ? (
                  pageRows.map((row, index) => (
                    <tr key={index} className="border-b border-brand-red/5 last:border-0">
                      <td className="px-4 py-4 text-brand-ink">{String(row.CustomerID ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.FullName ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.PhoneNumber ?? "")}</td>
                      <td className="px-4 py-4 text-brand-ink">{String(row.Email ?? "")}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-4 py-10 text-center text-brand-ink/60">
                      Không tìm thấy khách hàng phù hợp.
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
                <p className="text-sm uppercase tracking-[0.24em] text-brand-red">Tạo khách hàng</p>
                <h3 className="mt-2 font-display text-3xl text-brand-ink">Tạo mới hồ sơ khách hàng</h3>
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
                    setIsCreateOpen(false);
                    setError(null);
                  }}
                >
                  Hủy
                </Button>
                <Button type="submit" className="px-5 py-3" disabled={submitting}>
                  {submitting ? "Đang xử lý..." : "Lưu khách hàng"}
                </Button>
              </div>
            </form>
          </Panel>
        </div>
      ) : null}
    </>
  );
}
