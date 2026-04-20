const apiBaseUrl = (window as Window & { __PTIT_BANK_API__?: string }).__PTIT_BANK_API__ ?? "http://localhost:4000";

type RequestOptions = {
  method?: string;
  body?: unknown;
  token?: string | null;
  query?: Record<string, string>;
};

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const queryString = options.query ? `?${new URLSearchParams(options.query).toString()}` : "";
  const response = await fetch(`${apiBaseUrl}${path}${queryString}`, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {})
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });

  if (!response.ok) {
    const payload = await response.json().catch(() => ({ message: "Không thể xử lý yêu cầu" }));
    const fieldErrors = Object.values(payload?.issues?.fieldErrors ?? {})
      .flat()
      .filter((value): value is string => typeof value === "string" && value.trim().length > 0);
    const formErrors = (payload?.issues?.formErrors ?? []).filter((value: unknown): value is string => typeof value === "string" && value.trim().length > 0);
    const detailedMessage = [...fieldErrors, ...formErrors].join(". ");

    throw new Error(detailedMessage || payload.message || "Không thể xử lý yêu cầu");
  }

  return response.json() as Promise<T>;
}
