import request from 'supertest';
import { app } from '../app';
import * as db from '../db';

describe('Machine API Tests (Phase 2)', () => {
  const ownerUser = {
    id: 'aaaaaaaa-1111-2222-3333-444444444444',
    firebase_uid: 'uid_owner_1',
    phone_number: '+94771234567',
    email: null,
    full_name: 'Nimal Bandara',
    role: 'owner',
    gn_division: 'Padaviya Town',
    preferred_lang: 'si',
    status: 'active',
    created_at: new Date(),
    updated_at: new Date(),
  };

  const farmerUser = {
    id: 'bbbbbbbb-1111-2222-3333-444444444444',
    firebase_uid: 'uid_farmer_1',
    phone_number: '+94779876543',
    email: null,
    full_name: 'Sunil Perera',
    role: 'farmer',
    gn_division: 'Sripura',
    preferred_lang: 'si',
    status: 'active',
    created_at: new Date(),
    updated_at: new Date(),
  };

  beforeEach(() => {
    jest.spyOn(db, 'query').mockImplementation(async (sql: string, params?: any[]) => {
      // Mock auth lookup
      if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
        const uid = params?.[0];
        if (uid && uid.includes('owner')) {
          return { rows: [ownerUser], rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        if (uid && uid.includes('farmer')) {
          return { rows: [farmerUser], rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      }
      return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('POST /api/v1/machines', () => {
    it('requires authentication token', async () => {
      const res = await request(app).post('/api/v1/machines').send({
        machine_type: 'four_wheel_tractor',
        brand: 'Massey Ferguson',
        drive_type: '4wd',
        rate_amount: 3500,
        rate_unit: 'hour',
        service_gn_divisions: ['Padaviya Town'],
      });

      expect(res.status).toBe(401);
      expect(res.body.error).toBe('unauthorized');
    });

    it('rejects listing creation if user is only a farmer', async () => {
      const res = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer dev_farmer_+94779876543')
        .send({
          machine_type: 'four_wheel_tractor',
          brand: 'Massey Ferguson',
          drive_type: '4wd',
          rate_amount: 3500,
          rate_unit: 'hour',
          service_gn_divisions: ['Padaviya Town'],
        });

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('owner_only');
    });

    it('FR-2.8/2.9: rejects four-wheel tractor without drive type (drive_type_required)', async () => {
      const res = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer dev_owner_+94771234567')
        .send({
          machine_type: 'four_wheel_tractor',
          brand: 'Massey Ferguson',
          // drive_type omitted
          rate_amount: 3500,
          rate_unit: 'hour',
          service_gn_divisions: ['Padaviya Town'],
        });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('drive_type_required');
    });

    it('FR-2.9: rejects drive type on non-four-wheel tractor (drive_type_not_allowed)', async () => {
      const res = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer dev_owner_+94771234567')
        .send({
          machine_type: 'two_wheel_tractor',
          brand: 'Kubota',
          drive_type: '4wd', // Not allowed on 2-wheel tractor
          rate_amount: 1800,
          rate_unit: 'hour',
          service_gn_divisions: ['Padaviya Town'],
        });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('drive_type_not_allowed');
    });

    it('FR-2.1/2.6: successfully creates machine with brand and valid drive type', async () => {
      const mockCreated = {
        id: 'mmmmmmmm-1111-2222-3333-444444444444',
        owner_id: ownerUser.id,
        machine_type: 'four_wheel_tractor',
        brand: 'John Deere',
        drive_type: '4wd',
        model_name: '5050D',
        rate_amount: 4000,
        rate_unit: 'hour',
        photo_url: null,
        service_gn_divisions: ['Padaviya Town', 'Sripura'],
        is_active: true,
        created_at: new Date(),
        updated_at: new Date(),
      };

      jest.spyOn(db, 'query').mockImplementation(async (sql: string, params?: any[]) => {
        if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
          return { rows: [ownerUser], rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        if (sql.includes('INSERT INTO machines')) {
          return { rows: [mockCreated], rowCount: 1, command: 'INSERT', oid: 0, fields: [] };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      });

      const res = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer dev_owner_+94771234567')
        .send({
          machine_type: 'four_wheel_tractor',
          brand: 'John Deere',
          drive_type: '4wd',
          model_name: '5050D',
          rate_amount: 4000,
          rate_unit: 'hour',
          service_gn_divisions: ['Padaviya Town', 'Sripura'],
        });

      expect(res.status).toBe(201);
      expect(res.body.brand).toBe('John Deere');
      expect(res.body.drive_type).toBe('4wd');
      expect(res.body.machine_type).toBe('four_wheel_tractor');
    });
  });

  describe('GET /api/v1/machines', () => {
    it('returns machine list matching filters', async () => {
      const mockList = [
        {
          id: 'mmmmmmmm-1111-2222-3333-444444444444',
          owner_id: ownerUser.id,
          machine_type: 'four_wheel_tractor',
          brand: 'Tafe',
          drive_type: '2wd',
          model_name: '45 DI',
          rate_amount: 3200,
          rate_unit: 'hour',
          photo_url: null,
          service_gn_divisions: ['Padaviya Town'],
          is_active: true,
          owner_name: 'Nimal Bandara',
          owner_phone: '+94771234567',
          average_rating: 4.8,
          review_count: 5,
        },
      ];

      jest.spyOn(db, 'query').mockImplementation(async (sql: string) => {
        if (sql.includes('FROM machines m')) {
          return { rows: mockList, rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      });

      const res = await request(app).get('/api/v1/machines?gn_division=Padaviya+Town');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(1);
      expect(res.body[0].brand).toBe('Tafe');
      expect(res.body[0].drive_type).toBe('2wd');
      expect(res.body[0].owner_name).toBe('Nimal Bandara');
    });
  });

  describe('DELETE /api/v1/machines/:id', () => {
    it('FR-2.4: allows owner to soft-deactivate machine', async () => {
      const existingMachine = {
        id: 'mmmmmmmm-1111-2222-3333-444444444444',
        owner_id: ownerUser.id,
        is_active: true,
      };

      jest.spyOn(db, 'query').mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM users WHERE firebase_uid')) {
          return { rows: [ownerUser], rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        if (sql.includes('SELECT * FROM machines WHERE id')) {
          return { rows: [existingMachine], rowCount: 1, command: 'SELECT', oid: 0, fields: [] };
        }
        if (sql.includes('UPDATE machines SET is_active = false')) {
          return { rows: [], rowCount: 1, command: 'UPDATE', oid: 0, fields: [] };
        }
        return { rows: [], rowCount: 0, command: 'SELECT', oid: 0, fields: [] };
      });

      const res = await request(app)
        .delete('/api/v1/machines/mmmmmmmm-1111-2222-3333-444444444444')
        .set('Authorization', 'Bearer dev_owner_+94771234567');

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('deactivated');
    });
  });
});
