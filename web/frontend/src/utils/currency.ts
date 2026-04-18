const MONEY_KEYS = new Set([
  "Amount",
  "Balance",
  "InitialDeposit",
  "PrincipalAmount",
  "RemainingPrincipal",
  "PrincipalPaid",
  "InterestPaid",
  "PenaltyFee",
  "TotalBalance"
]);

export function formatCurrency(value: number | string | null | undefined) {
  return `${Intl.NumberFormat("vi-VN").format(Number(value ?? 0))} VNĐ`;
}

export function isMoneyKey(key: string) {
  return MONEY_KEYS.has(key);
}
