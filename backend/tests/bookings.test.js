const request = require('supertest');
const app = require('../server');
const db = require('../src/models/db');

// Mock the database pool and clients
const mockClient = {
  query: jest.fn(),
  release: jest.fn()
};

jest.mock('../src/models/db', () => ({
  query: jest.fn(),
  getClient: jest.fn(() => Promise.resolve(mockClient))
}));

describe('Bookings API Endpoints', () => {
  let mockFarmer;
  let mockOwner;
  let mockSlot;
  let mockBooking;

  beforeEach(() => {
    jest.clearAllMocks();

    mockFarmer = {
      id: 'farmer-uuid-222',
      phone_number: '+94778888888',
      firebase_uid: 'mock-farmer-uid',
      role: 'farmer'
    };

    mockOwner = {
      id: 'owner-uuid-111',
      phone_number: '+94777777777',
      firebase_uid: 'mock-owner-uid',
      role: 'owner'
    };

    mockSlot = {
      id: 'slot-uuid-333',
      machine_id: 'machine-uuid-444',
      slot_date: '2026-08-10',
      start_time: '08:00',
      end_time: '12:00',
      status: 'open',
      machine_type: 'four_wheel_tractor'
    };

    mockBooking = {
      id: 'booking-uuid-555',
      slot_id: 'slot-uuid-333',
      farmer_id: 'farmer-uuid-222',
      land_location: 'Near tank',
      land_size_acres: 2.5,
      status: 'requested',
      machine_type: 'four_wheel_tractor',
      slot_date: '2026-08-10'
    };
    
    // Default db.query mocks
    db.query.mockResolvedValue({ rows: [] });
  });

  describe('POST /api/v1/bookings', () => {
    it('should fail if land_size_acres is missing or <= 0', async () => {
      // Mock verify token finding farmer
      db.query.mockResolvedValueOnce({ rows: [mockFarmer] });

      const response = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({
          slot_id: 'slot-uuid-333'
          // land_size_acres missing
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
    });

    it('should fail if slot status is not open', async () => {
      // Mock token verification finds farmer
      db.query.mockResolvedValueOnce({ rows: [mockFarmer] });

      // Mock client queries for transaction
      mockClient.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({ rows: [{ ...mockSlot, status: 'booked' }] }); // SELECT FOR UPDATE

      const response = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({
          slot_id: 'slot-uuid-333',
          land_size_acres: 3.0
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('slot_no_longer_available');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    });

    it('should succeed if slot is open, marking slot pending and booking requested', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockFarmer] });

      mockClient.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({ rows: [mockSlot] }) // SELECT FOR UPDATE (slot status: open)
        .mockResolvedValueOnce({}) // UPDATE slot to pending
        .mockResolvedValueOnce({ rows: [mockBooking] }) // INSERT booking
        .mockResolvedValueOnce({}); // COMMIT

      const response = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({
          slot_id: 'slot-uuid-333',
          land_size_acres: 2.5,
          land_location: 'Near tank'
        });

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('requested');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
    });
  });

  describe('PATCH /api/v1/bookings/:id/respond', () => {
    it('should confirm booking and mark slot booked when action is confirm', async () => {
      // Token check resolves to machine owner
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      // Mock transaction query sequence
      mockClient.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({
          rows: [{
            ...mockBooking,
            owner_id: mockOwner.id, // is machine owner
            slot_status: 'pending'
          }]
        }) // SELECT FOR UPDATE booking
        .mockResolvedValueOnce({}) // UPDATE booking status to confirmed
        .mockResolvedValueOnce({}) // UPDATE slot status to booked
        .mockResolvedValueOnce({}); // COMMIT

      const response = await request(app)
        .patch('/api/v1/bookings/booking-uuid-555/respond')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({ action: 'confirm' });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('confirmed');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
    });

    it('should reject booking and release slot to open when action is reject', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockOwner] });

      mockClient.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({
          rows: [{
            ...mockBooking,
            owner_id: mockOwner.id,
            slot_status: 'pending'
          }]
        }) // SELECT FOR UPDATE
        .mockResolvedValueOnce({}) // UPDATE booking status to rejected
        .mockResolvedValueOnce({}) // UPDATE slot status to open
        .mockResolvedValueOnce({}); // COMMIT

      const response = await request(app)
        .patch('/api/v1/bookings/booking-uuid-555/respond')
        .set('Authorization', 'Bearer mock-owner-token')
        .send({ action: 'reject' });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('rejected');
    });

    it('should block response if requester is not the machine owner', async () => {
      db.query.mockResolvedValueOnce({ rows: [mockFarmer] }); // Not the owner

      mockClient.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({
          rows: [{
            ...mockBooking,
            owner_id: 'some-other-owner-id',
            slot_status: 'pending'
          }]
        });

      const response = await request(app)
        .patch('/api/v1/bookings/booking-uuid-555/respond')
        .set('Authorization', 'Bearer mock-farmer-token')
        .send({ action: 'confirm' });

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('forbidden');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    });
  });
});
