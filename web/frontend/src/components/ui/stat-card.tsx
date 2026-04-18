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
  const valueSizeClass = value.length > 16 ? "text-[1.05rem]" : value.length > 10 ? "text-[1.25rem]" : "text-[1.55rem]";

  return (
    <Panel className="overflow-hidden rounded-[24px] px-4 py-3">
      <div className="relative min-h-[62px]">
        <div className="min-w-0 pr-14">
          <p className="text-[10px] uppercase tracking-[0.18em] text-brand-ink/60">{label}</p>
          <p className={`mt-1 font-display leading-none text-brand-ink ${valueSizeClass}`}>{value}</p>
        </div>
        <div className={`absolute right-0 top-0 rounded-2xl p-2 ${tone}`}>
          <Icon className="h-4 w-4" />
        </div>
      </div>
    </Panel>
  );
}
