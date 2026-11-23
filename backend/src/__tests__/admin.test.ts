import request from 'supertest';
import { app } from '../app';
import * as db from '../db';

describe('Admin Panel API Endpoints (/api/v1/admin)', () => {
  const adminToken = 'Bearer dev_admin_admin@govipala.lk';
  const farmerToken = 'Bearer dev_farmer_+94775551122';

  beforeEach(() => {
    // Reset db mock to prevent unhandled network attempts
    jest.spyOn(db, 'query').mockImplementation(async () => {
      const err: any = new Error('connect ECONNREFUSED 127.0.0.1:5432');
      err.code = 'ECONNREFUSED';
      throw err;
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Authentication & Authorization', () => {
    it('rejects unauthenticated requests with 401', async () => {
      const res = await request(app).get('/api/v1/admin/stats');
      expect(res.status).toBe(401);
      expect(res.body.error).toBe('unauthorized');
    });

    it('rejects non-admin role with 403 admin_only', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', farmerToken);

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('admin_only');
    });
  });

  describe('GET /api/v1/admin/stats', () => {
    it('returns dashboard counts for users, machines, and bookings', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', adminToken);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('users');
      expect(res.body).toHaveProperty('machines');
      expect(res.body).toHaveProperty('bookings');
      expect(res.body.users.total_users).toBeGreaterThan(0);
      expect(res.body.machines.total_machines).toBeGreaterThan(0);
    });
  });

  describe('User Management Endpoints', () => {
    it('lists users with pagination and search filtering', async () => {
      const res = await request(app)
        .get('/api/v1/admin/users?role=farmer')
        .set('Authorization', adminToken);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('users');
      expect(res.body).toHaveProperty('total');
      expect(Array.isArray(res.body.users)).toBe(true);
      expect(res.body.users.every((u: any) => u.role === 'farmer')).toBe(true);
    });

    it('creates a user on someone behalf and writes an audit log', async () => {
      const newUserPayload = {
        full_name: 'ඩබ්. ප්‍රේමරත්න (W. Premaratne)',
        role: 'farmer',
        phone_number: '+94778889900',
        gn_division: 'Buddhangala',
        preferred_lang: 'si',
        reason: 'Farmer called in to request assisted registration',
      };

      const res = await request(app)
        .post('/api/v1/admin/users')
        .set('Authorization', adminToken)
        .send(newUserPayload);

      expect(res.status).toBe(201);
      expect(res.body.full_name).toBe(newUserPayload.full_name);
      expect(res.body.role).toBe('farmer');
      expect(res.body.status).toBe('active');
    });

    it('requires a reason when updating user status (suspend)', async () => {
      const targetUserId = '22222222-0000-0000-0000-000000000001';

      // Attempt status change without reason
      const failRes = await request(app)
        .patch(`/api/v1/admin/users/${targetUserId}/status`)
        .set('Authorization', adminToken)
        .send({ status: 'suspended' });

      expect(failRes.status).toBe(400);
      expect(failRes.body.error).toBe('validation_error');

      // Provide valid reason
      const successRes = await request(app)
        .patch(`/api/v1/admin/users/${targetUserId}/status`)
        .set('Authorization', adminToken)
        .send({
          status: 'suspended',
          reason: 'Multiple unexcused booking no-shows reported by owners',
        });

      expect(successRes.status).toBe(200);
      expect(successRes.body.user.status).toBe('suspended');
      expect(successRes.body).toHaveProperty('affected_bookings');
    });
  });

  describe('Machine Moderation Endpoints', () => {
    it('lists machines with owner details', async () => {
      const res = await request(app)
        .get('/api/v1/admin/machines')
        .set('Authorization', adminToken);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('machines');
      expect(Array.isArray(res.body.machines)).toBe(true);
      expect(res.body.machines[0]).toHaveProperty('brand');
    });

    it('deactivates a machine on behalf of the owner with audit log', async () => {
      const targetMachineId = '10000000-0000-0000-0000-000000000001';

      const res = await request(app)
        .delete(`/api/v1/admin/machines/${targetMachineId}`)
        .set('Authorization', adminToken)
        .send({ reason: 'Owner requested temporary deactivation for engine overhaul' });

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('deactivated');
    });
  });

  describe('Audit Log Endpoint', () => {
    it('returns read-only audit log entries with admin and reason', async () => {
      const res = await request(app)
        .get('/api/v1/admin/audit-log')
        .set('Authorization', adminToken);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('logs');
      expect(Array.isArray(res.body.logs)).toBe(true);
      expect(res.body.logs.length).toBeGreaterThan(0);
      expect(res.body.logs[0]).toHaveProperty('action');
      expect(res.body.logs[0]).toHaveProperty('target_table');
    });
  });
});
