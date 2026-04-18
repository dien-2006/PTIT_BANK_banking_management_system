import type { FormEvent } from "react";
import { useState } from "react";
import { ArrowRight, LockKeyhole, UserCircle2 } from "lucide-react";
import { Button } from "../components/ui/button";
import { Panel } from "../components/ui/panel";
import type { Session } from "../types";
import { apiRequest } from "../api/client";

type LoginPageProps = {
  onLogin: (session: Session) => void;
};

export function LoginPage({ onLogin }: LoginPageProps) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const session = await apiRequest<Session>("/api/auth/login", {
        method: "POST",
        body: { username, password }
      });
      onLogin(session);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Đăng nhập thất bại");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen overflow-hidden bg-hero-pattern px-4 py-4 md:px-5 md:py-5">
      <div className="mx-auto grid h-full max-w-[1480px] gap-5 lg:grid-cols-[1.08fr_0.92fr]">
        <section className="relative hidden overflow-hidden rounded-[36px] bg-brand-red p-8 text-white shadow-panel lg:block lg:p-12">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.16),transparent_24%),radial-gradient(circle_at_bottom_left,rgba(214,165,65,0.22),transparent_28%)]" />
          <div className="relative flex h-full flex-col">
            <img src="/ptit-logo.png" alt="PTIT" className="h-16 rounded-3xl bg-white p-2" />
            <p className="mt-10 text-sm uppercase tracking-[0.4em] text-white/70">Không gian ngân hàng số</p>
            <h1 className="mt-4 max-w-xl font-display text-5xl leading-tight">
              Quản lý giao dịch, thẻ và khoản vay trong một khung PTIT BANK thống nhất.
            </h1>
            <div className="mt-auto grid gap-4 md:grid-cols-3">
              {[
                "Nghiệp vụ chạy trực tiếp qua stored procedure",
                "Phân quyền theo vai trò nhân sự",
                "Tổng quan, báo cáo và lịch sử kiểm soát"
              ].map((item) => (
                <div key={item} className="rounded-3xl border border-white/10 bg-white/10 p-4 backdrop-blur">
                  <p className="text-sm font-medium">{item}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <Panel className="flex h-full items-center">
          <form className="w-full space-y-6" onSubmit={handleSubmit}>
            <div>
              <p className="text-sm uppercase tracking-[0.24em] text-brand-red">Đăng nhập nhân viên</p>
              <h2 className="mt-2 font-display text-3xl text-brand-ink">Truy cập hệ thống</h2>
              <p className="mt-2 text-sm text-brand-ink/60">Xác thực qua `sp_SystemUserLogin` để vào đúng màn hình theo vai trò.</p>
            </div>

            <label className="block space-y-2">
              <span className="text-sm font-medium text-brand-ink">Tên đăng nhập</span>
              <div className="flex items-center gap-3 rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3">
                <UserCircle2 className="h-5 w-5 text-brand-red" />
                <input
                  className="w-full bg-transparent outline-none"
                  placeholder="Nhập tên đăng nhập"
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                />
              </div>
            </label>

            <label className="block space-y-2">
              <span className="text-sm font-medium text-brand-ink">Mật khẩu</span>
              <div className="flex items-center gap-3 rounded-2xl border border-brand-red/10 bg-brand-cream px-4 py-3">
                <LockKeyhole className="h-5 w-5 text-brand-red" />
                <input
                  type="password"
                  className="w-full bg-transparent outline-none"
                  placeholder="Nhập mật khẩu"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                />
              </div>
            </label>

            {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}

            <Button type="submit" className="flex w-full items-center justify-center gap-2 py-3" disabled={loading}>
              {loading ? "Đang đăng nhập..." : "Vào PTIT BANK"}
              <ArrowRight className="h-4 w-4" />
            </Button>
          </form>
        </Panel>
      </div>
    </div>
  );
}
