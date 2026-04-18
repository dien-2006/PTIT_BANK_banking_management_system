import { BankingRepository } from "../repositories/banking-repository.js";

export class BankingService {
  constructor(private readonly repository: BankingRepository) {}

  getDashboardOverview() {
    return this.repository.getDashboardOverview();
  }

  getTopCustomers() {
    return this.repository.getTopCustomers();
  }

  getTopBranches() {
    return this.repository.getTopBranches();
  }

  getCustomers() {
    return this.repository.getCustomers();
  }

  addCustomer(payload: unknown) {
    return this.repository.addCustomer(payload);
  }

  registerOnlineAccount(payload: unknown) {
    return this.repository.registerOnlineAccount(payload);
  }

  getBranches() {
    return this.repository.getBranches();
  }

  getAccountTypes() {
    return this.repository.getAccountTypes();
  }

  getAccounts() {
    return this.repository.getAccounts();
  }

  openAccount(payload: unknown) {
    return this.repository.openAccount(payload);
  }

  updateAccountStatus(payload: unknown) {
    return this.repository.updateAccountStatus(payload);
  }

  deposit(payload: unknown) {
    return this.repository.deposit(payload);
  }

  withdraw(payload: unknown) {
    return this.repository.withdraw(payload);
  }

  transfer(payload: unknown) {
    return this.repository.transfer(payload);
  }

  getTransactionHistory(payload: unknown) {
    return this.repository.getTransactionHistory(payload);
  }

  getCards() {
    return this.repository.getCards();
  }

  issueCard(payload: unknown) {
    return this.repository.issueCard(payload);
  }

  getLoans() {
    return this.repository.getLoans();
  }

  getLoanTypes() {
    return this.repository.getLoanTypes();
  }

  createLoan(payload: unknown) {
    return this.repository.createLoan(payload);
  }

  payLoanInstallment(payload: unknown) {
    return this.repository.payLoanInstallment(payload);
  }
}
