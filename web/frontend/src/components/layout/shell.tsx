import type { PropsWithChildren } from "react";
import { LogOut, ShieldCheck } from "lucide-react";
import { Sidebar } from "./sidebar";
import type { NavItem, User } from "../../types";
import { Button } from "../ui/button";

type ShellProps = PropsWithChildren<{
  user: User;
  items: NavItem[];
  onLogout: () => void;
}>;

export function Shell({ user, items, onLogout, children }: ShellProps) {
  return (
    <div className="h-screen overflow-hidden bg-hero-pattern p-4 md:p-5">
      <div className="mx-auto grid h-full max-w-[1600px] gap-5 lg:grid-cols-[280px_minmax(0,1fr)]">
        <Sidebar user={user} items={items} />
        <main className="grid min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-3">
          <div className="flex flex-col gap-2.5 rounded-[26px] border border-white/70 bg-white/80 px-5 py-3.5 shadow-panel backdrop-blur md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.22em] text-brand-red">Trung tâm điều hành ngân hàng</p>
              <h1 className="mt-1 font-display text-[1.8rem] leading-tight text-brand-ink">Bảng điều khiển PTIT BANK</h1>
            </div>
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-2 rounded-2xl bg-brand-cream px-3.5 py-2 text-sm text-brand-ink">
                <ShieldCheck className="h-3.5 w-3.5 text-brand-red" />
                Phiên làm việc bảo mật JWT
              </div>
              <Button variant="ghost" className="flex items-center gap-2 px-3.5 py-2" onClick={onLogout}>
                <LogOut className="h-4 w-4" />
                Đăng xuất
              </Button>
            </div>
          </div>
          <div className="min-h-0 overflow-hidden">{children}</div>
        </main>
      </div>
    </div>
  );
}
