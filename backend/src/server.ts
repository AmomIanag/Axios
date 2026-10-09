import 'dotenv/config';

import { createApp } from './app.js';
import { FirebaseTokenVerifier, FirestoreConnectionStore } from './firebase_adapters.js';
import { HttpPluggyGateway } from './pluggy_gateway.js';

const clientId = process.env.PLUGGY_CLIENT_ID;
const clientSecret = process.env.PLUGGY_CLIENT_SECRET;
if (!clientId || !clientSecret) {
  throw new Error('PLUGGY_CLIENT_ID e PLUGGY_CLIENT_SECRET são obrigatórios.');
}

const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

const app = createApp({
  tokenVerifier: new FirebaseTokenVerifier(),
  connections: new FirestoreConnectionStore(),
  pluggy: new HttpPluggyGateway(
    clientId,
    clientSecret,
    process.env.PLUGGY_BASE_URL,
  ),
  allowedOrigins,
});

const port = Number(process.env.PORT ?? 8080);
app.listen(port, () => {
  console.info(`Axios backend ativo na porta ${port}.`);
});
