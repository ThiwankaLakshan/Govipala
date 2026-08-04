const request = require('supertest');
const app = require('../server');
const db = require('../src/models/db');

// Mock the database pool
jest.mock('../src/models/db', () => ({
  query: jest.fn()
}));

describe('Reviews API Endpoints', () => {
  let mockUserFarmer;
  let mockUserOwner;
  let mockCompletedBooking;
  let mockRequestedBooking;

  // State variables for robust order-independent mock database matching
  let currentAuthUser;
  let currentBookingRecord;
  let currentReviewResult;

  beforeEach(() => {
    db.query.mockReset();

    mockUserFarmer = {
      id: 'farmer-uuid-999',
      phone_number: '+94771112222',
      firebase_uid: 'farmer-uid',
      role: 'farmer',
      full_name: 'Farmer Siri'
    };

    mockUserOwner = {
      id: 'owner-uuid-888',
      phone_number: '+94773334444',
      firebase_uid: 'owner-uid',
      role: 'owner',
      full_name: 'Owner Kamal'
    };

    mockCompletedBooking = {
      id: 'booking-completed-uuid',
      slot_id: 'slot-uuid-1',
      farmer_id: 'farmer-uuid-999',
      owner_id: 'owner-uuid-888',
      status: 'completed'
    };

    mockRequestedBooking = {
      id: 'booking-requested-uuid',
      slot_id: 'slot-uuid-2',
      farmer_id: 'farmer-uuid-999',
      owner_id: 'owner-uuid-888',
      status: 'requested'
    };

    // Default states
    currentAuthUser = mockUserFarmer;
    currentBookingRecord = mockCompletedBooking;
    currentReviewResult = null;

    // Define robust mock database dispatcher
    db.query.mockImplementation((sql, params) => {
      const normalizedSql = sql.trim().replace(/\s+/g, ' ');
      
      if (normalizedSql.includes('SELECT * FROM users')) {
        return Promise.resolve({ rows: currentAuthUser ? [currentAuthUser] : [] });
      }
      
      if (normalizedSql.includes('SELECT b.*, m.owner_id')) {
        return Promise.resolve({ rows: currentBookingRecord ? [currentBookingRecord] : [] });
      }
      
      if (normalizedSql.includes('INSERT INTO reviews')) {
        if (currentReviewResult === 'duplicate-error') {
          const err = new Error('Unique constraint violation');
          err.code = '23505';
          return Promise.reject(err);
        }
        return Promise.resolve({ rows: currentReviewResult ? [currentReviewResult] : [] });
      }
      
      return Promise.resolve({ rows: [] });
    });
  });

  describe('POST /api/v1/reviews', () => {
    it('should fail if rating is missing or invalid range', async () => {
      const response = await request(app)
        .post('/api/v1/reviews')
        .set('Authorization', 'Bearer mock-token')
        .send({
          booking_id: 'booking-completed-uuid',
          rating: 6 // Invalid
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('validation_failed');
    });

    it('should fail if booking status is not completed', async () => {
      currentBookingRecord = mockRequestedBooking; // Set to requested booking

      const response = await request(app)
        .post('/api/v1/reviews')
        .set('Authorization', 'Bearer mock-token')
        .send({
          booking_id: 'booking-requested-uuid',
          rating: 5
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('invalid_action');
    });

    it('should fail if reviewer is not a participant in the booking', async () => {
      const mockStranger = {
        id: 'stranger-uuid-777',
        phone_number: '+94775556666',
        firebase_uid: 'stranger-uid',
        role: 'farmer'
      };

      currentAuthUser = mockStranger; // Set requester to stranger

      const response = await request(app)
        .post('/api/v1/reviews')
        .set('Authorization', 'Bearer mock-token')
        .send({
          booking_id: 'booking-completed-uuid',
          rating: 4
        });

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('forbidden');
    });

    it('should submit review successfully, resolving other participant as reviewee', async () => {
      const expectedReview = {
        id: 'review-uuid-123',
        booking_id: 'booking-completed-uuid',
        reviewer_id: 'farmer-uuid-999',
        reviewee_id: 'owner-uuid-888',
        rating: 5,
        comment: 'Great tractor and service!'
      };

      currentReviewResult = expectedReview;

      const response = await request(app)
        .post('/api/v1/reviews')
        .set('Authorization', 'Bearer mock-token')
        .send({
          booking_id: 'booking-completed-uuid',
          rating: 5,
          comment: 'Great tractor and service!'
        });

      expect(response.status).toBe(201);
      expect(response.body.rating).toBe(5);
      expect(response.body.reviewee_id).toBe('owner-uuid-888');
    });

    it('should handle conflict duplicate reviews on same booking', async () => {
      currentReviewResult = 'duplicate-error';

      const response = await request(app)
        .post('/api/v1/reviews')
        .set('Authorization', 'Bearer mock-token')
        .send({
          booking_id: 'booking-completed-uuid',
          rating: 5
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('already_reviewed');
    });
  });
});
