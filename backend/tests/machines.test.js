const request = require('supertest');
const app = require('../server');
const db = require('../src/models/db');

// Mock the database queries
jest.mock('../src/models/db', () => ({
  query: jest.fn()
}));

describe('Machines API Endpoints', () => {
  let mockOwner;
  let mockFarmer;

  beforeEach(() => {
    jest.clearAllMocks();

    mockOwner = {
      id: 'owner-uuid-111',
      phone_number: '+94777777777',
      firebase_uid: 'mock-owner-uid',
      full_name: 'Amara Bandara',
      role: 'owner',
      gn_division: 'Padaviya Town'
    };

    mockFarmer = {
      id: 'farmer-uuid-222',
      phone_number: '+94778888888',
      firebase_uid: 'mock-farmer-uid',
      full_name: 'Kamal Silva',
      role: 'farmer',
      gn_division: 'Sripura'
    };
  });

  describe('POST /api/v1/machines', () => {
    it('should return 403 if authenticated user is a farmer', async () => {
      // Mock db token check finding a farmer
      db.query.mockResolvedValueOnce({ rows: [mockFarmer] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({
          machine_type: 'four_wheel_tractor',
          rate_amount: 3500,
          rate_unit: 'day',
          service_gn_divisions: ['Padaviya Town']
        });

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('forbidden');
    });

    it('should fail if required fields are missing', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'four_wheel_tractor'
          // rate_amount, rate_unit, service_gn_divisions missing
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
    });

    it('should fail if machine_type is invalid (e.g. water_pump which was removed)', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'water_pump', // removed
          rate_amount: 3000,
          rate_unit: 'day',
          service_gn_divisions: ['Padaviya Town']
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
      expect(response.body.message).toContain('machine_type must be one of');
    });

    it('should fail if a tractor is missing paddy_type suitability', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'four_wheel_tractor',
          rate_amount: 3000,
          rate_unit: 'day',
          service_gn_divisions: ['Padaviya Town']
          // paddy_type missing
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
      expect(response.body.message).toContain('paddy_type (mud or dry) is required');
    });

    it('should fail if tractor paddy_type is invalid (e.g. both which was removed)', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'four_wheel_tractor',
          paddy_type: 'both', // removed, only mud/dry allowed
          rate_amount: 3000,
          rate_unit: 'day',
          service_gn_divisions: ['Padaviya Town']
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
      expect(response.body.message).toContain('paddy_type must be either "mud" or "dry"');
    });

    it('should fail if GN division is outside Padaviya list', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'four_wheel_tractor',
          paddy_type: 'mud',
          rate_amount: 3000,
          rate_unit: 'day',
          service_gn_divisions: ['Colombo', 'Sripura'] // Colombo is invalid
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
      expect(response.body.message).toContain('divisions are invalid: Colombo');
    });

    it('should successfully create tractor listing with valid parameters', async () => {
      const mockResult = {
        id: 'machine-uuid-999',
        owner_id: mockOwner.id,
        machine_type: 'four_wheel_tractor',
        model_name: 'TAFE 45 DI',
        paddy_type: 'mud',
        rate_amount: 3200,
        rate_unit: 'day',
        service_gn_divisions: ['Padaviya Town', 'Sripura'],
        is_active: true
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockOwner] }) // Token verification user lookup
        .mockResolvedValueOnce({ rows: [mockResult] }); // Machine insertion return

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'four_wheel_tractor',
          model_name: 'TAFE 45 DI',
          paddy_type: 'mud',
          rate_amount: 3200,
          rate_unit: 'day',
          service_gn_divisions: ['Padaviya Town', 'Sripura']
        });

      expect(response.status).toBe(201);
      expect(response.body).toEqual(mockResult);
    });

    it('should successfully create combine harvester (setting paddy_type to null)', async () => {
      const mockResult = {
        id: 'machine-uuid-888',
        owner_id: mockOwner.id,
        machine_type: 'combine_harvester',
        model_name: 'Kubota DC-70G',
        paddy_type: null,
        rate_amount: 15000,
        rate_unit: 'acre',
        service_gn_divisions: ['Sripura'],
        is_active: true
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockOwner] })
        .mockResolvedValueOnce({ rows: [mockResult] });

      const response = await request(app)
        .post('/api/v1/machines')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          machine_type: 'combine_harvester',
          model_name: 'Kubota DC-70G',
          rate_amount: 15000,
          rate_unit: 'acre',
          service_gn_divisions: ['Sripura']
        });

      expect(response.status).toBe(201);
      expect(response.body.paddy_type).toBeNull();
    });
  });

  describe('GET /api/v1/machines', () => {
    it('should return list of machines matching search criteria', async () => {
      const mockMachines = [
        { id: '1', machine_type: 'four_wheel_tractor', service_gn_divisions: ['Sripura'], owner_name: 'Amara', average_rating: 4.50 }
      ];

      db.query
        .mockResolvedValueOnce({ rows: [mockFarmer] }) // Token check
        .mockResolvedValueOnce({ rows: mockMachines }); // Fetch query

      const response = await request(app)
        .get('/api/v1/machines?machine_type=four_wheel_tractor&gn_division=Sripura')
        .set('Authorization', 'Bearer mock-farmer-token');

      expect(response.status).toBe(200);
      expect(response.body).toHaveLength(1);
      expect(response.body[0].id).toBe('1');
    });
  });

  describe('PATCH /api/v1/machines/:id', () => {
    it('should prevent updating a machine listing owned by another user', async () => {
      const existingMachine = {
        id: 'machine-uuid-xyz',
        owner_id: 'different-owner-id',
        machine_type: 'combine_harvester'
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockOwner] }) // Token check (user is mockOwner.id = 'owner-uuid-111')
        .mockResolvedValueOnce({ rows: [existingMachine] }); // Machine fetch check

      const response = await request(app)
        .patch('/api/v1/machines/machine-uuid-xyz')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          rate_amount: 5000
        });

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('forbidden');
    });
  });
});
