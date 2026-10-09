import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { z } from 'zod';

import type {
  ConnectionStore,
  PluggyGateway,
  TokenVerifier,
} from './contracts.js';
import { PluggyApiError } from './pluggy_gateway.js';

declare global {
  namespace Express {
    interface Request {
      authUid?: string;
    }
  }
}

export interface AppDependencies {
  tokenVerifier: TokenVerifier;
  connections: ConnectionStore;
  pluggy: PluggyGateway;
  allowedOrigins?: string[];
}

const itemSchema = z.object({ itemId: z.uuid() });

export function createApp(dependencies: AppDependencies) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(
    cors({
      origin(origin, callback) {
        if (!origin || dependencies.allowedOrigins?.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Origem não autorizada.'));
        }
      },
    }),
  );
  app.use(express.json({ limit: '32kb' }));
  app.use(
    rateLimit({
      windowMs: 60_000,
      limit: 60,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  app.get('/health', (_request, response) => {
    response.json({ status: 'ok' });
  });

  app.use('/api', async (request, response, next) => {
    const authorization = request.header('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      response.status(401).json({ error: 'Autenticação Firebase obrigatória.' });
      return;
    }
    try {
      const user = await dependencies.tokenVerifier.verify(
        authorization.substring('Bearer '.length),
      );
      request.authUid = user.uid;
      next();
    } catch {
      response.status(401).json({ error: 'Token Firebase inválido ou expirado.' });
    }
  });

  app.post('/api/pluggy/connect-token', async (request, response, next) => {
    try {
      const accessToken = await dependencies.pluggy.createConnectToken(
        request.authUid!,
      );
      response.json({ accessToken });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/pluggy/items/link', async (request, response, next) => {
    try {
      const { itemId } = itemSchema.parse(request.body);
      const item = await dependencies.pluggy.getItem(itemId);
      if (item.clientUserId !== request.authUid) {
        response.status(403).json({ error: 'Item não pertence ao usuário.' });
        return;
      }
      await dependencies.connections.link(request.authUid!, {
        itemId,
        connectorId: item.connector?.id,
        connectorName: item.connector?.name,
        status: item.status,
      });
      response.status(201).json({ itemId });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/pluggy/connections', async (request, response, next) => {
    try {
      response.json({ results: await dependencies.connections.list(request.authUid!) });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/pluggy/transactions', async (request, response, next) => {
    try {
      const { itemId } = itemSchema.parse(request.query);
      if (!(await dependencies.connections.isOwnedBy(request.authUid!, itemId))) {
        response.status(403).json({ error: 'Conexão não pertence ao usuário.' });
        return;
      }
      const accounts = await dependencies.pluggy.listAccounts(itemId);
      const transactions = (
        await Promise.all(
          accounts.map(async (account) => {
            const accountId = asString(account.id);
            if (!accountId) return [];
            const raw = await dependencies.pluggy.listTransactions(accountId);
            return raw.map((transaction) => normalizeTransaction(transaction, account));
          }),
        )
      ).flat();
      response.json({ results: transactions });
    } catch (error) {
      next(error);
    }
  });

  app.use((error: unknown, _request: Request, response: Response, _next: NextFunction) => {
    if (error instanceof z.ZodError) {
      response.status(400).json({ error: 'Parâmetros inválidos.' });
      return;
    }
    if (error instanceof PluggyApiError) {
      const status = error.status === 401 || error.status === 403 ? 503 : 502;
      response.status(status).json({
        error: 'Pluggy Sandbox indisponível ou sem autorização no momento.',
      });
      return;
    }
    response.status(500).json({ error: 'Erro interno do backend.' });
  });

  return app;
}

function normalizeTransaction(
  transaction: Record<string, unknown>,
  account: Record<string, unknown>,
) {
  const externalId = asString(transaction.id);
  const description =
    asString(transaction.description) ?? 'Transação Pluggy';
  const amount = asNumber(transaction.amount) ?? 0;
  const type = asString(transaction.type)?.toUpperCase();
  const operationType = asString(transaction.operationType)?.toUpperCase();
  const category = mapCategory(
    asString(transaction.category),
    description,
    type,
  );
  return {
    externalId,
    description,
    date: asString(transaction.date),
    amountInCents: Math.round(Math.abs(amount) * 100),
    type: type === 'CREDIT' ? 'income' : 'expense',
    category,
    pending: asString(transaction.status)?.toUpperCase() === 'PENDING',
    excludedFromBudget: operationType === 'PAGAMENTO_FATURA',
    accountId: asString(account.id),
    accountType: asString(account.type),
  };
}

function mapCategory(
  rawCategory: string | undefined,
  description: string,
  type: string | undefined,
) {
  if (type === 'CREDIT') return 'receita';
  const value = `${rawCategory ?? ''} ${description}`.toLowerCase();
  if (/food|meal|restaurant|mercado|supermercado/.test(value)) return 'alimentacao';
  if (/transport|uber|fuel|posto/.test(value)) return 'transporte';
  if (/health|pharmacy|farmacia/.test(value)) return 'saude';
  if (/education|livraria|course/.test(value)) return 'educacao';
  if (/housing|rent|aluguel/.test(value)) return 'moradia';
  if (/transfer|pix|pagamento_fatura/.test(value)) return 'transferencia';
  if (/entertainment|cinema|streaming/.test(value)) return 'lazer';
  return 'outros';
}

function asString(value: unknown): string | undefined {
  return typeof value === 'string' && value.length > 0 ? value : undefined;
}

function asNumber(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}
