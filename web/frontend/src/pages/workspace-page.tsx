import type { FormEvent } from "react";
import { useState } from "react";
import { apiRequest } from "../api/client";
import { Button } from "../components/ui/button";
import { DataTable } from "../components/ui/data-table";
import { Panel } from "../components/ui/panel";

type WorkspaceAction = {
  title: string;
  endpoint: string;
  method?: "GET" | "POST" | "PATCH";
  fields: { name: string; label: string; type?: string; placeholder?: string }[];
  submitLabel: string;
  onSuccess?: (payload: unknown) => Promise<void> | void;
};

type WorkspacePageProps = {
  token: string;
  heading: string;
  summary: string;
  actions: WorkspaceAction[];
  rows: Array<Record<string, unknown>>;
  columns: { key: string; header: string }[];
  filterKeys: string[];
  onRefresh: () => Promise<void>;
};

export function WorkspacePage({
  token,
  heading,
  summary,
  actions,
  rows,
  columns,
  filterKeys,
  onRefresh
}: WorkspacePageProps) {
  const [forms, setForms] = useState<Record<string, Record<string, string>>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState<string | null>(null);

  const handleSubmit = async (action: WorkspaceAction, event: FormEvent) => {
    event.preventDefault();
    setSubmitting(action.title);
    setError(null);

    try {
      const payload = forms[action.title] ?? {};
      const result = await apiRequest(action.endpoint, {
        method: action.method ?? "POST",
        token,
        body: action.method === "GET" ? undefined : payload,
        query: action.method === "GET" ? payload : undefined
      });
      if (action.onSuccess) {
        await action.onSuccess(result);
      } else {
        await onRefresh();
      }
      setForms((current) => ({ ...current, [action.title]: {} }));
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Không thể xử lý yêu cầu");
    } finally {
      setSubmitting(null);
    }
  };

  return (
    <div className="grid h-full min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-5">
      <Panel>
        <p className="text-sm uppercase tracking-[0.24em] text-brand-red">{heading}</p>
        <h2 className="mt-2 font-display text-2xl text-brand-ink">{summary}</h2>
      </Panel>

      <div className="grid min-h-0 gap-5 xl:grid-cols-[minmax(0,1.05fr)_minmax(0,1.15fr)]">
        <div className="grid min-h-0 gap-5 content-start xl:grid-cols-2">
          {actions.map((action) => (
            <Panel key={action.title} className="flex min-h-0 flex-col overflow-hidden">
              <h3 className="font-display text-xl text-brand-ink">{action.title}</h3>
              <form className="mt-5 flex-1 space-y-4 overflow-y-auto pr-1" onSubmit={(event) => handleSubmit(action, event)}>
                {action.fields.map((field) => (
                  <label key={field.name} className="block space-y-2">
                    <span className="text-sm font-medium text-brand-ink">{field.label}</span>
                    <input
                      type={field.type ?? "text"}
                      className="w-full rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3 outline-none"
                      placeholder={field.placeholder}
                      value={forms[action.title]?.[field.name] ?? ""}
                      onChange={(event) =>
                        setForms((current) => ({
                          ...current,
                          [action.title]: {
                            ...current[action.title],
                            [field.name]: event.target.value
                          }
                        }))
                      }
                    />
                  </label>
                ))}
                <Button type="submit" className="w-full py-3" disabled={submitting === action.title}>
                  {submitting === action.title ? "Đang xử lý..." : action.submitLabel}
                </Button>
              </form>
            </Panel>
          ))}
        </div>

        <div className="grid min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-4">
          {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}

          <DataTable
            title={heading}
            rows={rows}
            filterKeys={filterKeys as never}
            columns={columns.map((column) => ({ key: column.key as never, header: column.header }))}
          />
        </div>
      </div>
    </div>
  );
}
