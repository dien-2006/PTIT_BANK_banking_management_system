import type { ButtonHTMLAttributes, PropsWithChildren } from "react";
import clsx from "clsx";

type ButtonProps = PropsWithChildren<
  ButtonHTMLAttributes<HTMLButtonElement> & {
    variant?: "primary" | "secondary" | "ghost";
  }
>;

export function Button({ children, className, variant = "primary", ...props }: ButtonProps) {
  return (
    <button
      className={clsx(
        "rounded-2xl px-4 py-2 text-sm font-semibold transition duration-200",
        variant === "primary" && "bg-brand-red text-white hover:bg-[#851723]",
        variant === "secondary" && "bg-brand-gold text-brand-ink hover:brightness-95",
        variant === "ghost" && "border border-white/60 bg-white/70 text-brand-ink hover:bg-white",
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}
