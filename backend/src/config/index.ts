import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/govipala',
  
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || 'govipala-pilot',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  },

  // Allows testing and development without live Firebase SMS OTP project
  devAuthEnabled: process.env.DEV_AUTH_ENABLED === 'true' || process.env.NODE_ENV !== 'production',

  sms: {
    apiKey: process.env.SMS_GATEWAY_API_KEY,
    senderId: process.env.SMS_GATEWAY_SENDER_ID || 'GOVIPALA',
  },
};
