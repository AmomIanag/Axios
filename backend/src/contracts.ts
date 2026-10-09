export interface AuthenticatedUser {
  uid: string;
}

export interface TokenVerifier {
  verify(token: string): Promise<AuthenticatedUser>;
}

export interface LinkedPluggyItem {
  itemId: string;
  connectorId?: number;
  connectorName?: string;
  status?: string;
}

export interface ConnectionStore {
  link(uid: string, item: LinkedPluggyItem): Promise<void>;
  isOwnedBy(uid: string, itemId: string): Promise<boolean>;
  list(uid: string): Promise<LinkedPluggyItem[]>;
}

export interface PluggyItem {
  id: string;
  clientUserId?: string | null;
  status?: string;
  connector?: { id?: number; name?: string };
}

export interface PluggyGateway {
  createConnectToken(uid: string): Promise<string>;
  getItem(itemId: string): Promise<PluggyItem>;
  listAccounts(itemId: string): Promise<Record<string, unknown>[]>;
  listTransactions(accountId: string): Promise<Record<string, unknown>[]>;
}
