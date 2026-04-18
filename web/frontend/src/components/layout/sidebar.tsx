import { Landmark, PiggyBank } from "lucide-react";
import { NavLink } from "react-router-dom";
import clsx from "clsx";
import type { NavItem, User } from "../../types";

type SidebarProps = {
  user: User;
  items: NavItem[];
};

export function Sidebar({ user, items }: SidebarProps) {
  const visibleItems = items.filter((item) => item.roles.includes(user.role));
  const roleLabel =
    user.role === "Admin"
      ? "Quản trị viên"
      : user.role === "Branch Manager"
        ? "Quản lý chi nhánh"
        : user.role === "Loan Officer"
          ? "Nhân viên tín dụng"
          : user.role === "Teller"
            ? "Giao dịch viên"
            : user.role;

  return (
    <aside className="flex h-full flex-col overflow-hidden rounded-[32px] bg-brand-red p-5 text-white shadow-panel">
      <div className="flex items-center gap-3 border-b border-white/15 pb-5">
        <img src="/ptit-logo.png" alt="PTIT logo" className="h-12 w-12 rounded-2xl bg-white object-cover p-1" />
        <div>
          <p className="font-display text-xl">PTIT BANK</p>
          <p className="text-sm text-white/70">{roleLabel}</p>
        </div>
      </div>

      <div className="mt-5 rounded-3xl bg-white/10 p-4">
        <div className="flex items-center gap-3">
          <div className="rounded-2xl bg-white/15 p-3">
            <Landmark className="h-5 w-5" />
          </div>
          <div>
            <p className="font-semibold">{user.username}</p>
            <p className="text-sm text-white/70">Vận hành nghiệp vụ an toàn</p>
          </div>
        </div>
      </div>

      <nav className="mt-6 flex-1 space-y-2 overflow-y-auto pr-1">
        {visibleItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              clsx(
                "flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition",
                isActive ? "bg-white text-brand-red" : "text-white/80 hover:bg-white/10 hover:text-white"
              )
            }
          >
            <PiggyBank className="h-4 w-4" />
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
