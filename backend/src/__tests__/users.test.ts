import request from 'supertest';
import { app } from '../app';
import * as db from '../db';

describe('Auth & User API Tests', () => {
  beforeEach(() => {
    // Default DB mock: no existing user found
    jest.spyOn(db, 'query').mockImplementation(async (sql: string, params?: any[]) => {
      if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      }
      return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('GET /health', () => {
    it('returns 200 with service status', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
      expect(res.body.service).toBe('govipala-api');
    });
  });

  describe('GET /api/v1/locations/gn-divisions', () => {
    it('returns Padaviya GN division list', async () => {
      const res = await request(app).get('/api/v1/locations/gn-divisions');
      expect(res.status).toBe(200);
      expect(res.body.ds_division).toBe('Padaviya');
      expect(Array.isArray(res.body.gn_divisions)).toBe(true);
      expect(res.body.gn_divisions).toContain('Padaviya Town');
      expect(res.body.gn_divisions).toContain('Sripura');
    });
  });

  describe('POST /api/v1/users/register', () => {
    it('requires Bearer token', async () => {
      const res = await request(app)
        .post('/api/v1/users/register')
        .send({
          full_name: 'Test Farmer',
          role: 'farmer',
          gn_division: 'Padaviya Town',
        });

      expect(res.status).toBe(401);
      expect(res.body.error).toBe('unauthorized');
    });

    it('rejects public registration with admin role (FR-1.6)', async () => {
      const res = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer dev_admin_test@govipala.lk')
        .send({
          full_name: 'Hacker Admin',
          role: 'admin',
          gn_division: 'Padaviya Town',
        });

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('admin_registration_forbidden');
    });

    it('successfully registers a farmer and returns 201', async () => {
      jest.spyOn(db, 'query').mockImplementation(async (sql: string, params?: any[]) => {
        if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
          return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
        }
        if (sql.includes('INSERT INTO users')) {
          return {
            rows: [
              {
                id: '11111111-2222-3333-4444-555555555555',
                firebase_uid: params?.[0],
                phone_number: params?.[1],
                email: params?.[2],
                full_name: params?.[3],
                role: params?.[4],
                gn_division: params?.[5],
                preferred_lang: params?.[6],
                status: 'active',
                created_at: new Date(),
                updated_at: new Date(),
              },
            ],
            rowCount: 1,
            command: 'INSERT',
            oid: 0,
            fields: [],
          };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      });

      const res = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer dev_farmer_+94771234567')
        .send({
          full_name: 'Sunil Perera',
          role: 'farmer',
          gn_division: 'Padaviya Town',
          preferred_lang: 'si',
        });

      expect(res.status).toBe(201);
      expect(res.body.full_name).toBe('Sunil Perera');
      expect(res.body.role).toBe('farmer');
      expect(res.body.gn_division).toBe('Padaviya Town');
      expect(res.body.status).toBe('active');
    });

    it('rejects suspended users with 403 account_suspended (FR-1.7)', async () => {
      jest.spyOn(db, 'query').mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
          return {
            rows: [
              {
                id: '22222222-3333-4444-5555-666666666666',
                firebase_uid: 'uid_suspended',
                phone_number: '+94770000000',
                email: null,
                full_name: 'Suspended User',
                role: 'owner',
                gn_division: 'Sripura',
                preferred_lang: 'si',
                status: 'suspended',
                created_at: new Date(),
                updated_at: new Date(),
              },
            ],
            rowCount: 1,
            command: 'SELECT',
            oid: 0,
            fields: [],
          };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      });

      const res = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer dev_owner_+94770000000');

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('account_suspended');
    });
  });
});
