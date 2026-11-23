import admin from 'firebase-admin';
import { config } from '../config';

let firebaseApp: admin.app.App | null = null;

export function getFirebaseAdmin(): admin.app.App | null {
  if (firebaseApp) return firebaseApp;

  if (config.firebase.clientEmail && config.firebase.privateKey) {
    try {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.firebase.projectId,
          clientEmail: config.firebase.clientEmail,
          privateKey: config.firebase.privateKey,
        }),
      });
      console.log('✅ Firebase Admin SDK initialized with service account.');
    } catch (err) {
      console.warn('⚠️ Could not initialize Firebase Admin SDK:', err);
    }
  } else {
    console.log('ℹ️ Firebase credentials not provided. Running in dev auth mode.');
  }

  return firebaseApp;
}

export interface DecodedAuthToken {
  uid: string;
  phone_number?: string;
  email?: string;
}

export async function verifyIdToken(token: string): Promise<DecodedAuthToken> {
  const app = getFirebaseAdmin();

  // If mock/dev token or running in dev auth mode without live Firebase cert
  if (token.startsWith('dev_') || (!app && config.devAuthEnabled)) {
    const parts = token.split('_');
    const roleHint = parts[1] || 'farmer';
    const identifier = parts.slice(2).join('_') || '+94771112233';

    const isEmail = identifier.includes('@');
    return {
      uid: `uid_${roleHint}_${Buffer.from(identifier).toString('base64').substring(0, 16)}`,
      phone_number: isEmail ? undefined : identifier,
      email: isEmail ? identifier : undefined,
    };
  }

  if (!app) {
    throw new Error('Firebase Admin SDK is not configured and dev auth token was not provided.');
  }

  const decoded = await app.auth().verifyIdToken(token);
  return {
    uid: decoded.uid,
    phone_number: decoded.phone_number,
    email: decoded.email,
  };
}
