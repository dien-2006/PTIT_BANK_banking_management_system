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
    throw new Error(payload.message ?? "Không thể xử lý yêu cầu");
  }

  return response.json() as Promise<T>;
}
