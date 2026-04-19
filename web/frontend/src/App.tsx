import { useEffect, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { apiRequest } from "./api/client";
import { Shell } from "./components/layout/shell";
import { AccountsPage } from "./pages/accounts-page";
import { CardsPage } from "./pages/cards-page";
import { CustomersPage } from "./pages/customers-page";
import { DashboardPage } from "./pages/dashboard-page";
import { LoansPage } from "./pages/loans-page";
import { LoginPage } from "./pages/login-page";
import { ReportsPage } from "./pages/reports-page";
import { TransactionsPage } from "./pages/transactions-page";
import type { NavItem, Session } from "./types";

const NAV_ITEMS: NavItem[] = [
  { label: "Tổng quan", path: "/dashboard", roles: ["Admin", "Branch Manager"] },
  { label: "Khách hàng", path: "/customers", roles: ["Admin", "Teller"] },
  { label: "Tài khoản", path: "/accounts", roles: ["Admin", "Teller"] },
  { label: "Giao dịch", path: "/transactions", roles: ["Admin", "Teller"] },
  { label: "Thẻ ngân hàng", path: "/cards", roles: ["Admin", "Teller"] },
  { label: "Khoản vay", path: "/loans", roles: ["Admin", "Loan Officer"] },
  { label: "Báo cáo", path: "/reports", roles: ["Admin", "Branch Manager"] }
];

type AppData = {
  dashboard: { overview?: Record<string, number>; topCustomers: Array<Record<string, unknown>>; topBranches: Array<Record<string, unknown>> };
  customers: Array<Record<string, unknown>>;
  accounts: Array<Record<string, unknown>>;
  cards: Array<Record<string, unknown>>;
  loans: Array<Record<string, unknown>>;
  transactions: Array<Record<string, unknown>>;
};

const emptyData: AppData = {
  dashboard: { topCustomers: [], topBranches: [] },
  customers: [],
  accounts: [],
  cards: [],
  loans: [],
  transactions: []
};

function App() {
  const [session, setSession] = useState<Session | null>(() => {
    const saved = localStorage.getItem("ptit-bank-session");
    return saved ? (JSON.parse(saved) as Session) : null;
  });
  const [data, setData] = useState<AppData>(emptyData);

  const loadData = async () => {
    if (!session) {
      return;
    }

    const token = session.token;
    const requests: Promise<unknown>[] = [];
    const setters: Array<(payload: unknown) => void> = [];

    if (["Admin", "Branch Manager"].includes(session.user.role)) {
      requests.push(apiRequest("/api/dashboard", { token }));
      setters.push((payload) => setData((current) => ({ ...current, dashboard: payload as AppData["dashboard"] })));
    }

    if (["Admin", "Teller"].includes(session.user.role)) {
      requests.push(apiRequest("/api/customers", { token }));
      setters.push((payload) => setData((current) => ({ ...current, customers: payload as AppData["customers"] })));

      requests.push(apiRequest("/api/accounts", { token }));
      setters.push((payload) => setData((current) => ({ ...current, accounts: payload as AppData["accounts"] })));

      requests.push(apiRequest("/api/cards", { token }));
      setters.push((payload) => setData((current) => ({ ...current, cards: payload as AppData["cards"] })));

      requests.push(apiRequest("/api/transactions/history", { token }));
      setters.push((payload) => setData((current) => ({ ...current, transactions: payload as AppData["transactions"] })));
    }

    if (session.user.role === "Branch Manager") {
      requests.push(apiRequest("/api/transactions/history", { token }));
      setters.push((payload) => setData((current) => ({ ...current, transactions: payload as AppData["transactions"] })));
    }

    if (["Admin", "Loan Officer"].includes(session.user.role)) {
      requests.push(apiRequest("/api/loans", { token }));
      setters.push((payload) => setData((current) => ({ ...current, loans: payload as AppData["loans"] })));
    }

    const responses = await Promise.all(requests);
    responses.forEach((payload, index) => setters[index](payload));
  };

  useEffect(() => {
    if (session) {
      localStorage.setItem("ptit-bank-session", JSON.stringify(session));
      loadData().catch(console.error);
      return;
    }

    localStorage.removeItem("ptit-bank-session");
  }, [session]);

  if (!session) {
    return <LoginPage onLogin={setSession} />;
  }

  const defaultPath =
    session.user.role === "Teller"
      ? "/customers"
      : session.user.role === "Loan Officer"
        ? "/loans"
        : "/dashboard";

  return (
    <Shell
      user={session.user}
      items={NAV_ITEMS}
      onLogout={() => {
        setSession(null);
        setData(emptyData);
      }}
    >
      <Routes>
        <Route path="/" element={<Navigate to={defaultPath} replace />} />
        <Route path="/dashboard" element={<DashboardPage data={data.dashboard} />} />
        <Route path="/customers" element={<CustomersPage token={session.token} rows={data.customers} onRefresh={loadData} />} />
        <Route path="/accounts" element={<AccountsPage token={session.token} rows={data.accounts} onRefresh={loadData} />} />
        <Route path="/transactions" element={<TransactionsPage token={session.token} rows={data.transactions} onRefresh={loadData} />} />
        <Route path="/cards" element={<CardsPage token={session.token} rows={data.cards} onRefresh={loadData} />} />
        <Route path="/loans" element={<LoansPage token={session.token} rows={data.loans} onRefresh={loadData} />} />
        <Route path="/reports" element={<ReportsPage token={session.token} rows={data.transactions} onRefresh={loadData} />} />
      </Routes>
    </Shell>
  );
}

export default App;
