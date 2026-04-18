export type User = {
  userId: string | number;
  username: string;
  role: string;
  employeeId?: string | number | null;
  customerId?: string | number | null;
  branchId?: string | number | null;
};

export type Session = {
  token: string;
  user: User;
};

export type NavItem = {
  label: string;
  path: string;
  roles: string[];
};
