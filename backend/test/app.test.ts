import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';

import { createApp } from '../src/app.js';
import type {
  ConnectionStore,
  PluggyGateway,
  TokenVerifier,
} from '../src/contracts.js';
import { PluggyApiError } from '../src/pluggy_gateway.js';

const uid = 'user-123';
const itemId = '11111111-1111-4111-8111-111111111111';

function fixtures(overrides: Partial<{
  verifier: TokenVerifier;
  store: ConnectionStore;
  pluggy: PluggyGateway;
}> = {}) {
  const verifier: TokenVerifier = overrides.verifier ?? {
    verify: vi.fn(async () => ({ uid })),
  };
  const store: ConnectionStore = overrides.store ?? {
    link: vi.fn(async () => undefined),
    isOwnedBy: vi.fn(async () => true),
    list: vi.fn(async () => []),
  };
  const pluggy: PluggyGateway = overrides.pluggy ?? {
    createConnectToken: vi.fn(async () => 'connect-token'),
    getItem: vi.fn(async () => ({ id: itemId, clientUserId: uid })),
    listAccounts: vi.fn(async () => []),
    listTransactions: vi.fn(async () => []),
  };
  return { verifier, store, pluggy };
}

describe('API Pluggy protegida', () => {
  it('rejeita chamadas sem Firebase ID token', async () => {
    const deps = fixtures();
    const response = await request(createApp({
      tokenVerifier: deps.verifier,
      connections: deps.store,
      pluggy: deps.pluggy,
      allowedOrigins: [],
    })).post('/api/pluggy/connect-token');

    expect(response.status).toBe(401);
  });

  it('gera connect token usando o UID verificado', async () => {
    const deps = fixtures();
    const response = await request(createApp({
      tokenVerifier: deps.verifier,
      connections: deps.store,
      pluggy: deps.pluggy,
      allowedOrigins: [],
    }))
      .post('/api/pluggy/connect-token')
      .set('Authorization', 'Bearer firebase-token')
      .send({ uid: 'uid-forjado' });

    expect(response.status).toBe(200);
    expect(deps.pluggy.createConnectToken).toHaveBeenCalledWith(uid);
  });

  it('não associa item cujo clientUserId pertence a outro usuário', async () => {
    const deps = fixtures({
      pluggy: {
        createConnectToken: vi.fn(),
        getItem: vi.fn(async () => ({ id: itemId, clientUserId: 'outro' })),
        listAccounts: vi.fn(),
        listTransactions: vi.fn(),
      },
    });
    const response = await request(createApp({
      tokenVerifier: deps.verifier,
      connections: deps.store,
      pluggy: deps.pluggy,
      allowedOrigins: [],
    }))
      .post('/api/pluggy/items/link')
      .set('Authorization', 'Bearer firebase-token')
      .send({ itemId });

    expect(response.status).toBe(403);
    expect(deps.store.link).not.toHaveBeenCalled();
  });

  it('bloqueia transações de conexão pertencente a outro usuário', async () => {
    const deps = fixtures({
      store: {
        link: vi.fn(),
        isOwnedBy: vi.fn(async () => false),
        list: vi.fn(async () => []),
      },
    });
    const response = await request(createApp({
      tokenVerifier: deps.verifier,
      connections: deps.store,
      pluggy: deps.pluggy,
      allowedOrigins: [],
    }))
      .get(`/api/pluggy/transactions?itemId=${itemId}`)
      .set('Authorization', 'Bearer firebase-token');

    expect(response.status).toBe(403);
    expect(deps.pluggy.listAccounts).not.toHaveBeenCalled();
  });

  it('traduz bloqueio ou trial Pluggy em erro indisponível sem vazar detalhes', async () => {
    const deps = fixtures({
      pluggy: {
        createConnectToken: vi.fn(async () => {
          throw new PluggyApiError('segredo da resposta externa', 403);
        }),
        getItem: vi.fn(),
        listAccounts: vi.fn(),
        listTransactions: vi.fn(),
      },
    });
    const response = await request(createApp({
      tokenVerifier: deps.verifier,
      connections: deps.store,
      pluggy: deps.pluggy,
      allowedOrigins: [],
    }))
      .post('/api/pluggy/connect-token')
      .set('Authorization', 'Bearer firebase-token');

    expect(response.status).toBe(503);
    expect(response.body.error).toContain('indisponível');
    expect(response.text).not.toContain('segredo da resposta externa');
  });
});
