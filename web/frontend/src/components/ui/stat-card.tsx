import type { ComponentType } from "react";
import type { LucideIcon } from "lucide-react";
import { Panel } from "./panel";

type StatCardProps = {
  label: string;
  value: string;
  icon: LucideIcon | ComponentType<{ className?: string }>;
  tone: string;
};

export function StatCard({ label, value, icon: Icon, tone }: StatCardProps) {
  const displayValue = value.replace(" VNĐ", "");

  return (
    <Panel className="overflow-hidden rounded-[24px] px-4 py-3">
      <div className="relative min-h-[72px]">
        <div className="flex min-h-[72px] flex-col justify-center pr-16">
          <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">{label}</p>
          <div className="mt-2 flex items-baseline gap-2 whitespace-nowrap text-brand-ink">
            <span className="font-display text-[1.35rem] leading-none">{displayValue}</span>
          </div>
        </div>
        <div className={`absolute right-0 top-1/2 -translate-y-1/2 rounded-2xl p-2 ${tone}`}>
          <Icon className="h-4 w-4" />
        </div>
      </div>
    </Panel>
  );
}
