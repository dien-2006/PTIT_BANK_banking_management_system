import type { ReactNode } from "react";
import { useMemo, useState } from "react";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import { isMoneyKey, formatCurrency } from "../../utils/currency";
import { Panel } from "./panel";

type Column<T> = {
  key: keyof T;
  header: string;
  render?: (row: T) => ReactNode;
};

type DataTableProps<T extends Record<string, unknown>> = {
  title: string;
  rows: T[];
  columns: Column<T>[];
  filterKeys: (keyof T)[];
  pageSize?: number;
};

export function DataTable<T extends Record<string, unknown>>({
  title,
  rows,
  columns,
  filterKeys,
  pageSize = 6
}: DataTableProps<T>) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);

  const filteredRows = useMemo(() => {
    const normalized = query.toLowerCase();

    return rows.filter((row) =>
      filterKeys.some((key) => String(row[key] ?? "").toLowerCase().includes(normalized))
    );
  }, [filterKeys, query, rows]);

  const totalPages = Math.max(1, Math.ceil(filteredRows.length / pageSize));
  const pagedRows = filteredRows.slice((page - 1) * pageSize, page * pageSize);

  return (
    <Panel className="flex h-full min-h-0 flex-col space-y-4 overflow-hidden">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h3 className="font-display text-xl text-brand-ink">{title}</h3>
          <p className="text-sm text-brand-ink/60">Tìm kiếm, lọc và xem dữ liệu ngay trong khung nghiệp vụ.</p>
        </div>
        <label className="flex items-center gap-2 rounded-2xl border border-brand-red/15 bg-brand-cream px-4 py-3">
          <Search className="h-4 w-4 text-brand-red" />
          <input
            className="w-full bg-transparent text-sm outline-none"
            placeholder="Tìm dữ liệu..."
            value={query}
            onChange={(event) => {
              setQuery(event.target.value);
              setPage(1);
            }}
          />
        </label>
      </div>

      <div className="min-h-0 flex-1 overflow-auto rounded-3xl border border-brand-red/8">
        <table className="min-w-full text-left text-sm">
          <thead className="sticky top-0 bg-white/95 backdrop-blur">
            <tr className="border-b border-brand-red/10 text-brand-ink/60">
              {columns.map((column) => (
                <th key={String(column.key)} className="px-3 py-3 font-medium">
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {pagedRows.length ? (
              pagedRows.map((row, index) => (
                <tr key={index} className="border-b border-brand-red/5 last:border-0">
                  {columns.map((column) => (
                    <td key={String(column.key)} className="px-3 py-4 text-brand-ink">
                      {column.render
                        ? column.render(row)
                        : isMoneyKey(String(column.key))
                          ? formatCurrency(row[column.key] as number | string | null | undefined)
                          : String(row[column.key] ?? "")}
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={columns.length} className="px-3 py-8 text-center text-brand-ink/60">
                  Không có dữ liệu phù hợp.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between text-sm text-brand-ink/60">
        <span>
          Trang {page} / {totalPages}
        </span>
        <div className="flex gap-2">
          <button
            className="rounded-xl border border-brand-red/10 p-2 disabled:opacity-50"
            disabled={page === 1}
            onClick={() => setPage((current) => Math.max(1, current - 1))}
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button
            className="rounded-xl border border-brand-red/10 p-2 disabled:opacity-50"
            disabled={page === totalPages}
            onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
          >
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>
    </Panel>
  );
}
