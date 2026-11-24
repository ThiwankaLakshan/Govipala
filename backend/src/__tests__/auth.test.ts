import request from 'supertest';
import { app } from '../app';
import * as db from '../db';

describe('Auth & Login API Tests', () => {
  beforeEach(() => {
    jest.spyOn(db, 'query').mockImplementation(async (sql: string, params?: any[]) => {
      if (sql.includes('SELECT * FROM users WHERE phone_number')) {
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      }
      if (sql.includes('INSERT INTO users')) {
        return {
          rows: [{
            id: 'registered_u1',
            firebase_uid: 'dev_user_123',
            full_name: params ? params[1] : 'New User',
            role: params ? params[2] : 'farmer',
            phone_number: params ? params[3] : '+94771112233',
            gn_division: params ? params[4] : 'Padaviya Town',
            is_verified: true,
            created_at: new Date(),
          }],
          rowCount: 1,
          command: 'INSERT',
          oid: 0,
          fields: [],
        };
      }
      return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('GET /api/v1/auth/demo-credentials', () => {
    it('returns demo credentials for farmer, owner, and admin', async () => {
      const res = await request(app).get('/api/v1/auth/demo-credentials');
      expect(res.status).toBe(200);
      expect(res.body.farmer).toBeDefined();
      expect(res.body.farmer.password).toBe('farmer123');
      expect(res.body.machine_owner).toBeDefined();
      expect(res.body.machine_owner.password).toBe('owner123');
      expect(res.body.admin).toBeDefined();
      expect(res.body.admin.password).toBe('admin123');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('logs in farmer with demo password farmer123', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          role: 'farmer',
          identifier: '0775551122',
          password: 'farmer123',
        });

      expect(res.status).toBe(200);
      expect(res.body.token).toBeDefined();
      expect(res.body.user.role).toBe('farmer');
    });

    it('logs in owner with demo password owner123', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          role: 'machine_owner',
          identifier: '0771234567',
          password: 'owner123',
        });

      expect(res.status).toBe(200);
      expect(res.body.token).toBeDefined();
      expect(['owner', 'machine_owner', 'both']).toContain(res.body.user.role);
    });

    it('logs in admin with demo password admin123', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          role: 'admin',
          identifier: 'admin@govipala.lk',
          password: 'admin123',
        });

      expect(res.status).toBe(200);
      expect(res.body.token).toBe('dev_admin');
      expect(res.body.user.role).toBe('admin');
    });

    it('rejects invalid password with 401', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          role: 'farmer',
          identifier: '0775551122',
          password: 'wrong_password',
        });

      expect(res.status).toBe(401);
      expect(res.body.error).toBe('invalid_credentials');
    });

    it('rejects missing password with 400', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          role: 'farmer',
          identifier: '0775551122',
        });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('validation_error');
    });
  });

  describe('POST /api/v1/auth/register', () => {
    it('creates a new account successfully', async () => {
      const uniquePhone = `077 ${Math.floor(1000000 + Math.random() * 8999999)}`;
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          full_name: 'Chaminda Silva',
          role: 'farmer',
          phone_number: uniquePhone,
          gn_division: 'Padaviya East',
        });

      expect(res.status).toBe(201);
      expect(res.body.token).toBeDefined();
      expect(res.body.user.full_name).toBe('Chaminda Silva');
    });

    it('rejects duplicate phone number with 409', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          full_name: 'Sunil Duplicate',
          role: 'owner',
          phone_number: '077 123 4567', // already in devUsers
          gn_division: 'Padaviya Town',
        });

      expect(res.status).toBe(409);
      expect(res.body.error).toBe('user_already_exists');
    });

    it('rejects invalid phone format with 400', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          full_name: 'Invalid User',
          role: 'farmer',
          phone_number: '123',
          gn_division: 'Padaviya East',
        });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('validation_error');
    });
  });
});
