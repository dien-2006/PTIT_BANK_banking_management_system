Bo CSV da sua theo create_table.txt:
- Chi giu CustomerType: Individual, Business
- Them CustomerOnlineAccount.csv
- BankTransaction.csv co cot Channel
- LoanPayment.csv co cot PaymentChannel
- AccountStatusHistory.csv co cot ChangedByType
- Bo cot LastTransactionDate o BankAccount
- Bo cot RemainingAmount o Loan

Kiem tra nhanh:
{
  "customer_types": [
    "Business",
    "Individual"
  ],
  "channels": [
    "ATM",
    "Counter",
    "InternetBanking"
  ],
  "payment_channels": [
    "Counter",
    "InternetBanking",
    "System"
  ],
  "card_types": [
    "ATM",
    "Debit"
  ],
  "card_statuses": [
    "Active",
    "Blocked",
    "Expired"
  ],
  "ash_changedby": [
    "Customer",
    "Employee",
    "System"
  ],
  "ash_same_status_rows": 0,
  "tr_counter_missing_emp": 0,
  "tr_noncounter_with_emp": 0,
  "lp_counter_missing_emp": 0,
  "lp_noncounter_with_emp": 0
}
