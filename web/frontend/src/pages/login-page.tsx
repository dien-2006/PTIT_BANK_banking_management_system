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

const loginHighlights = [
  "Quản lý giao dịch thông minh",
  "Phân quyền và bảo mật người dùng",
  "Theo dõi tài khoản và lịch sử giao dịch",
  "Quản lý khoản vay và thanh toán"
];

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
    <div className="min-h-screen bg-hero-pattern px-4 py-4 md:px-5 md:py-5">
      <div className="mx-auto flex min-h-[calc(100vh-2.5rem)] max-w-[1180px] items-center justify-center">
        <div className="grid w-full gap-5 xl:grid-cols-[0.94fr_0.76fr]">
          <section className="relative hidden min-h-[660px] overflow-hidden rounded-[30px] bg-brand-red px-9 py-8 text-white shadow-panel lg:block">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.16),transparent_22%),radial-gradient(circle_at_bottom_left,rgba(214,165,65,0.14),transparent_30%)]" />

            <div className="relative flex h-full flex-col justify-between">
              <div className="max-w-[545px] py-8 pl-1 pr-6 pt-24 md:pl-3 md:pr-8">
                <div className="mb-7 inline-flex items-center gap-4">
                  <div className="flex h-[74px] w-[74px] items-center justify-center rounded-[22px] bg-white">
                    <img src="/ptit-logo.png" alt="PTIT" className="h-12 w-12 object-contain" />
                  </div>
                  <span className="block font-display text-[2.25rem] font-bold tracking-[-0.04em] text-white">PTIT BANK</span>
                </div>
                <h1
                  className="font-display text-[1.72rem] font-semibold leading-[1.38] tracking-[-0.02em] text-white/96"
                  style={{ textAlign: "justify", textJustify: "inter-word" }}
                >
                  PTIT BANK mang đến một nền tảng quản lý ngân hàng toàn diện, kết hợp giữa hiệu năng, tính bảo mật và khả năng phân tích, giúp vận hành nghiệp vụ nhanh hơn, chính xác hơn và chuyên nghiệp hơn.
                </h1>
              </div>

              <div className="grid max-w-[620px] gap-3 pb-14 md:grid-cols-4">
                {loginHighlights.map((item) => (
                  <div key={item} className="rounded-[18px] border border-white/10 bg-white/8 px-4 py-3 backdrop-blur-sm">
                    <p className="text-[11px] font-semibold leading-4 text-white/92">{item}</p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          <Panel className="flex min-h-[660px] items-center rounded-[30px] border-white/60 bg-white/90 px-7 py-8 lg:px-8">
            <form className="mx-auto w-full max-w-[350px] space-y-5" onSubmit={handleSubmit}>
              <div>
                <p className="text-[10px] uppercase tracking-[0.28em] text-brand-red">Đăng nhập nhân viên</p>
                <h2 className="mt-3 font-display text-[2.2rem] leading-none text-brand-ink">Chào mừng trở lại</h2>
              </div>

              <label className="block space-y-2">
                <span className="text-[13px] font-semibold text-brand-ink">Tên đăng nhập</span>
                <div className="flex h-[54px] items-center gap-3 rounded-[18px] border border-brand-red/10 bg-brand-cream px-4">
                  <UserCircle2 className="h-4 w-4 text-brand-red" />
                  <input
                    className="w-full bg-transparent text-[15px] outline-none placeholder:text-brand-ink/35"
                    placeholder="Nhập tên đăng nhập"
                    value={username}
                    onChange={(event) => setUsername(event.target.value)}
                  />
                </div>
              </label>

              <label className="block space-y-2">
                <span className="text-[13px] font-semibold text-brand-ink">Mật khẩu</span>
                <div className="flex h-[54px] items-center gap-3 rounded-[18px] border border-brand-red/10 bg-brand-cream px-4">
                  <LockKeyhole className="h-4 w-4 text-brand-red" />
                  <input
                    type="password"
                    className="w-full bg-transparent text-[15px] outline-none placeholder:text-brand-ink/35"
                    placeholder="Nhập mật khẩu"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                </div>
              </label>

              {error ? <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-600">{error}</p> : null}

              <Button type="submit" className="flex h-[54px] w-full items-center justify-center gap-2 rounded-[18px] text-[15px] font-semibold" disabled={loading}>
                {loading ? "Đang đăng nhập..." : "Vào PTIT BANK"}
                <ArrowRight className="h-4 w-4" />
              </Button>
            </form>
          </Panel>
        </div>
      </div>
    </div>
  );
}
