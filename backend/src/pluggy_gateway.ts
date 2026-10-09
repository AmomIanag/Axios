import type { PluggyGateway, PluggyItem } from './contracts.js';

export class PluggyApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
  ) {
    super(message);
  }
}

export class HttpPluggyGateway implements PluggyGateway {
  private apiKey?: string;
  private apiKeyExpiresAt = 0;

  constructor(
    private readonly clientId: string,
    private readonly clientSecret: string,
    private readonly baseUrl = 'https://api.pluggy.ai',
  ) {}

  async createConnectToken(uid: string): Promise<string> {
    const payload = await this.request<{ accessToken: string }>(
      '/connect_token',
      {
        method: 'POST',
        body: JSON.stringify({
          options: { clientUserId: uid, avoidDuplicates: true },
        }),
      },
    );
    return payload.accessToken;
  }

  getItem(itemId: string): Promise<PluggyItem> {
    return this.request(`/items/${encodeURIComponent(itemId)}`);
  }

  async listAccounts(itemId: string): Promise<Record<string, unknown>[]> {
    const payload = await this.request<{ results?: Record<string, unknown>[] }>(
      `/accounts?itemId=${encodeURIComponent(itemId)}`,
    );
    return payload.results ?? [];
  }

  async listTransactions(
    accountId: string,
  ): Promise<Record<string, unknown>[]> {
    const results: Record<string, unknown>[] = [];
    let path: string | null =
      `/v2/transactions?accountId=${encodeURIComponent(accountId)}`;
    while (path != null) {
      const page: {
        results?: Record<string, unknown>[];
        next?: string | null;
      } = await this.request(path);
      results.push(...(page.results ?? []));
      path = page.next == null
        ? null
        : `/v2/transactions${page.next.startsWith('?') ? page.next : `?after=${encodeURIComponent(page.next)}`}`;
    }
    return results;
  }

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const apiKey = await this.getApiKey();
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': apiKey,
        ...init.headers,
      },
    });
    if (!response.ok) {
      throw new PluggyApiError(
        `Pluggy respondeu com status ${response.status}.`,
        response.status,
      );
    }
    return (await response.json()) as T;
  }

  private async getApiKey(): Promise<string> {
    if (this.apiKey && Date.now() < this.apiKeyExpiresAt) return this.apiKey;
    const response = await fetch(`${this.baseUrl}/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        clientId: this.clientId,
        clientSecret: this.clientSecret,
      }),
    });
    if (!response.ok) {
      throw new PluggyApiError(
        'Não foi possível autenticar o backend na Pluggy.',
        response.status,
      );
    }
    const payload = (await response.json()) as { apiKey?: string };
    if (!payload.apiKey) {
      throw new PluggyApiError('A Pluggy não retornou uma API key.', 502);
    }
    this.apiKey = payload.apiKey;
    this.apiKeyExpiresAt = Date.now() + 110 * 60 * 1000;
    return payload.apiKey;
  }
}
