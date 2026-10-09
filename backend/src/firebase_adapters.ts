import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

import type {
  ConnectionStore,
  LinkedPluggyItem,
  TokenVerifier,
} from './contracts.js';

function ensureFirebaseAdmin() {
  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
  }
}

export class FirebaseTokenVerifier implements TokenVerifier {
  constructor() {
    ensureFirebaseAdmin();
  }

  async verify(token: string): Promise<{ uid: string }> {
    const decoded = await getAuth().verifyIdToken(token, true);
    return { uid: decoded.uid };
  }
}

export class FirestoreConnectionStore implements ConnectionStore {
  constructor() {
    ensureFirebaseAdmin();
  }

  async link(uid: string, item: LinkedPluggyItem): Promise<void> {
    await getFirestore()
      .collection('users')
      .doc(uid)
      .collection('pluggyItems')
      .doc(item.itemId)
      .set({ ...item, ownerUid: uid, updatedAt: new Date() }, { merge: true });
  }

  async isOwnedBy(uid: string, itemId: string): Promise<boolean> {
    const document = await getFirestore()
      .collection('users')
      .doc(uid)
      .collection('pluggyItems')
      .doc(itemId)
      .get();
    return document.exists && document.data()?.ownerUid === uid;
  }

  async list(uid: string): Promise<LinkedPluggyItem[]> {
    const snapshot = await getFirestore()
      .collection('users')
      .doc(uid)
      .collection('pluggyItems')
      .get();
    return snapshot.docs.map((document) => {
      const data = document.data();
      return {
        itemId: document.id,
        connectorId:
          typeof data.connectorId === 'number' ? data.connectorId : undefined,
        connectorName:
          typeof data.connectorName === 'string'
            ? data.connectorName
            : undefined,
        status: typeof data.status === 'string' ? data.status : undefined,
      };
    });
  }
}
