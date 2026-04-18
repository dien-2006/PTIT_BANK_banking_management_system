import type { FormEvent } from "react";
import { useState } from "react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { DataTable } from "../components/ui/data-table";
import { Panel } from "../components/ui/panel";

type OperationsPageProps = {
  token: string;
  title: string;
  description: string;
  endpoint: string;
  rows: Array<Record<string, unknown>>;
  columns: { key: string; header: string }[];
  filterKeys: string[];
  formFields: { name: string; label: string; type?: string; placeholder?: string }[];
  submitLabel: string;
  onRefresh: () => Promise<void>;
};

export function OperationsPage({
  token,
  title,
  description,
  endpoint,
  rows,
  columns,
  filterKeys,
  formFields,
  submitLabel,
  onRefresh
}: OperationsPageProps) {
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      await apiRequest(endpoint, {
        method: "POST",
        token,
        body: formData
      });
      setFormData({});
      await onRefresh();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Không thể xử lý yêu cầu");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="grid h-full min-h-0 gap-5 xl:grid-cols-[420px_minmax(0,1fr)]">
      <Panel className="flex min-h-0 flex-col overflow-hidden">
        <div>
          <p className="text-sm uppercase tracking-[0.24em] text-brand-red">{title}</p>
          <h2 className="mt-2 font-display text-2xl text-brand-ink">{description}</h2>
        </div>
        <form className="mt-6 flex-1 space-y-4 overflow-y-auto pr-1" onSubmit={handleSubmit}>
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
          {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}
          <Button type="submit" disabled={submitting} className="w-full py-3">
            {submitting ? "Đang xử lý..." : submitLabel}
          </Button>
        </form>
      </Panel>

      <DataTable
        title={title}
        rows={rows}
        filterKeys={filterKeys as never}
        columns={columns.map((column) => ({ key: column.key as never, header: column.header }))}
      />
    </div>
  );
}
