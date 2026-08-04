const request = require('supertest');
const app = require('../server');
const db = require('../src/models/db');

// Mock the database query function
jest.mock('../src/models/db', () => ({
  query: jest.fn()
}));

describe('Users API Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default db.query mock to return empty rows (unregistered user case)
    db.query.mockResolvedValue({ rows: [] });
  });

  describe('GET /api/v1/users/me', () => {
    it('should return 401 if authorization header is missing', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('unauthorized');
    });

    it('should return 401 if authorization header has invalid format', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'InvalidToken');

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('unauthorized');
    });

    it('should return 404 if Firebase token is valid but user is not registered in PG', async () => {
      // Mock db lookup returning no records
      db.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer mock-uid-12345');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('user_not_registered');
      expect(response.body.firebaseUser).toBeDefined();
    });

    it('should return user profile if user is registered in PG', async () => {
      const mockUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        phone_number: '+94771234567',
        firebase_uid: 'mock-owner-uid',
        full_name: 'Amara Bandara',
        role: 'owner',
        gn_division: 'Padaviya Town',
        preferred_lang: 'en'
      };

      // Mock db lookup returning registered user
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer mock-owner-token');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockUser);
    });
  });

  describe('POST /api/v1/users/register', () => {
    it('should fail registration if required fields are missing', async () => {
      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer mock-uid-newuser')
        .send({
          full_name: 'Sumith Perera'
          // role and gn_division missing
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
    });

    it('should fail registration if role is invalid', async () => {
      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer mock-uid-newuser')
        .send({
          full_name: 'Sumith Perera',
          role: 'admin', // invalid
          gn_division: 'Sripura'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
    });

    it('should succeed registration with valid payload and return 201', async () => {
      const newUser = {
        id: '987f6543-e21b-12d3-a456-426614174000',
        phone_number: '+94778888888',
        firebase_uid: 'mock-farmer-uid',
        full_name: 'Kamal Silva',
        role: 'farmer',
        gn_division: 'Sripura',
        preferred_lang: 'en'
      };

      // First query (verifyFirebaseToken lookup) returns empty -> unregistered
      db.query.mockResolvedValueOnce({ rows: [] });
      // Second query (registration insert) returns the inserted user
      db.query.mockResolvedValueOnce({ rows: [newUser] });

      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({
          full_name: 'Kamal Silva',
          role: 'farmer',
          gn_division: 'Sripura',
          preferred_lang: 'en'
        });

      expect(response.status).toBe(201);
      expect(response.body).toEqual(newUser);
    });

    it('should return 409 if user is already registered', async () => {
      const mockUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        phone_number: '+94771234567',
        firebase_uid: 'mock-owner-uid',
        full_name: 'Amara Bandara',
        role: 'owner',
        gn_division: 'Padaviya Town'
      };

      // Mock verifyFirebaseToken finding user -> already registered
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({
          full_name: 'Amara Bandara',
          role: 'owner',
          gn_division: 'Padaviya Town'
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('already_registered');
    });
  });
});
