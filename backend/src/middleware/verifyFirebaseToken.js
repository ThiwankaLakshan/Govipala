const admin = require('firebase-admin');
const db = require('../models/db');

// Initialize Firebase Admin SDK if not already initialized
if (process.env.FIREBASE_PROJECT_ID && 
    process.env.FIREBASE_PRIVATE_KEY && 
    !process.env.FIREBASE_PRIVATE_KEY.includes('MOCKKEY') && 
    process.env.FIREBASE_CLIENT_EMAIL) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
  } catch (error) {
    if (!/already exists/.test(error.message)) {
      console.error('Firebase Admin init error:', error);
    }
  }
} else {
  console.warn('Firebase Admin credentials missing or mock key detected. Firebase token verification will fall back to mock auth in development/testing.');
}

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Authorization token is required (Bearer <token>)'
    });
  }

  const token = authHeader.split('Bearer ')[1];

  // Mock Authentication for development / testing
  if ((process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test') && token.startsWith('mock-')) {
    let mockUid = 'mock-uid-123';
    let mockPhone = '+94771234567';

    if (token === 'mock-owner-token') {
      mockUid = 'mock-owner-uid';
      mockPhone = '+94777777777';
    } else if (token === 'mock-farmer-token') {
      mockUid = 'mock-farmer-uid';
      mockPhone = '+94778888888';
    } else if (token.startsWith('mock-uid-')) {
      mockUid = token;
      mockPhone = '+9477' + Math.floor(1000000 + Math.random() * 9000000);
    }

    try {
      // Find user in PostgreSQL db
      const result = await db.query('SELECT * FROM users WHERE firebase_uid = $1', [mockUid]);
      if (result.rows.length > 0) {
        req.user = result.rows[0];
      } else {
        // Not registered yet, store firebase data for registration endpoint
        req.firebaseUser = {
          uid: mockUid,
          phone_number: mockPhone
        };
      }
      return next();
    } catch (err) {
      console.error('Mock database look up error:', err);
      return res.status(500).json({ error: 'server_error', message: 'Internal server error during auth' });
    }
  }

  // Real Firebase Token verification
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    const { uid, phone_number } = decodedToken;

    if (!phone_number) {
      return res.status(400).json({
        error: 'invalid_token',
        message: 'Firebase token must contain a verified phone number'
      });
    }

    const result = await db.query('SELECT * FROM users WHERE firebase_uid = $1', [uid]);
    if (result.rows.length > 0) {
      req.user = result.rows[0];
    } else {
      req.firebaseUser = {
        uid,
        phone_number
      };
    }
    
    next();
  } catch (error) {
    console.error('Firebase token verification error:', error);
    return res.status(401).json({
      error: 'invalid_token',
      message: 'Invalid or expired authentication token'
    });
  }
}

module.exports = verifyFirebaseToken;
