import request from 'supertest';
import { app } from '../app';
import { devBookings, devSlots } from '../models/bookingStore';
import { devReviews } from '../models/reviewStore';
import { devNotificationsLog } from '../services/notificationService';
import { devMachines } from '../controllers/machineController';
import { devAuditLogs } from '../services/auditService';

describe('Phase 4: Notifications Engine Tests (FR-6.1 - FR-6.4)', () => {
  const farmerToken = 'Bearer dev_farmer_+94775551122'; // Anura Kumara
  const ownerToken = 'Bearer dev_owner_+94771234567';  // Sunil Perera
  const adminToken = 'Bearer dev_admin';

  beforeEach(() => {
    devNotificationsLog.length = 0;
  });

  it('triggers push and SMS fallback notifications when a booking is created (FR-6.1, FR-6.3, FR-6.4)', async () => {
    // 1. Add an open slot for machine 1 (Sunil)
    const slotId = `slot-notif-test-${Date.now()}`;
    devSlots.push({
      id: slotId,
      machine_id: '10000000-0000-0000-0000-000000000001',
      slot_date: '2026-12-01',
      start_time: '08:00:00',
      end_time: '12:00:00',
      status: 'open',
      created_at: new Date(),
      updated_at: new Date(),
    });

    // 2. Farmer requests booking
    const res = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', farmerToken)
      .send({
        slot_id: slotId,
        land_location: 'Track 10, Padaviya',
      });

    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();

    // Verify notifications were logged for the owner
    const ownerNotifs = devNotificationsLog.filter(
      (n) => n.user_id === '11111111-0000-0000-0000-000000000001'
    );
    expect(ownerNotifs.length).toBeGreaterThanOrEqual(2); // push + sms
    const push = ownerNotifs.find((n) => n.channel === 'push');
    const sms = ownerNotifs.find((n) => n.channel === 'sms');

    expect(push).toBeDefined();
    expect(sms).toBeDefined();
    expect(push?.message).toContain('Massey Ferguson');
    expect(sms?.message).toContain('[Govipala Alert]');
  });

  it('triggers notification to farmer when owner confirms booking (FR-6.2)', async () => {
    // Create requested booking
    const bookingId = `book-notif-confirm-${Date.now()}`;
    devBookings.unshift({
      id: bookingId,
      slot_id: 's0000000-0000-0000-0000-000000000001',
      farmer_id: '22222222-0000-0000-0000-000000000001',
      land_location: 'Track 1',
      status: 'requested',
      created_by_admin: null,
      requested_at: new Date(),
      responded_at: null,
      completed_at: null,
      cancellation_reason: null,
      machine_brand: 'Massey Ferguson',
      machine_type: 'four_wheel_tractor',
    });

    const res = await request(app)
      .patch(`/api/v1/bookings/${bookingId}/respond`)
      .set('Authorization', ownerToken)
      .send({ action: 'confirm' });

    expect(res.status).toBe(200);

    // Verify farmer got confirmed notification
    const farmerNotifs = devNotificationsLog.filter(
      (n) => n.user_id === '22222222-0000-0000-0000-000000000001'
    );
    expect(farmerNotifs.length).toBeGreaterThanOrEqual(1);
    expect(farmerNotifs[0].title).toContain('තහවුරු විය');
  });

  it('allows user to query their notifications via GET /notifications/mine', async () => {
    const res = await request(app)
      .get('/api/v1/notifications/mine')
      .set('Authorization', farmerToken);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('allows admin to query audit log of notifications via GET /notifications/log (FR-6.4)', async () => {
    const res = await request(app)
      .get('/api/v1/notifications/log')
      .set('Authorization', adminToken);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});

describe('Phase 5: Ratings & Reviews Engine Tests (FR-7.1 - FR-7.4)', () => {
  const farmerToken = 'Bearer dev_farmer_+94775551122'; // Anura Kumara
  const ownerToken = 'Bearer dev_owner_+94771234567';  // Sunil Perera
  const adminToken = 'Bearer dev_admin';

  let testBookingId: string;

  beforeAll(() => {
    testBookingId = `book-review-test-${Date.now()}`;
    devBookings.unshift({
      id: testBookingId,
      slot_id: 's0000000-0000-0000-0000-000000000001',
      farmer_id: '22222222-0000-0000-0000-000000000001',
      owner_id: '11111111-0000-0000-0000-000000000001',
      land_location: 'Track 3 Paddy field',
      status: 'in_progress', // not yet completed!
      created_by_admin: null,
      requested_at: new Date(),
      responded_at: new Date(),
      completed_at: null,
      cancellation_reason: null,
    });
  });

  it('rejects review on a booking that is not completed (FR-7.1)', async () => {
    const res = await request(app)
      .post(`/api/v1/bookings/${testBookingId}/review`)
      .set('Authorization', farmerToken)
      .send({
        rating: 5,
        comment: 'Great tractor work',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('invalid_booking_status');
  });

  it('rejects review with invalid rating outside 1..5', async () => {
    // Mark booking completed
    const b = devBookings.find((item) => item.id === testBookingId)!;
    b.status = 'completed';

    const res = await request(app)
      .post(`/api/v1/bookings/${testBookingId}/review`)
      .set('Authorization', farmerToken)
      .send({
        rating: 6, // Invalid
        comment: 'Too high',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('successfully creates review for completed booking by farmer (FR-7.1)', async () => {
    const res = await request(app)
      .post(`/api/v1/bookings/${testBookingId}/review`)
      .set('Authorization', farmerToken)
      .send({
        rating: 5,
        comment: 'නියමිත වේලාවට පැමිණියා. විශිෂ්ට සේවාවක්! (Excellent punctual service)',
      });

    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.rating).toBe(5);
    expect(res.body.reviewer_name).toBeDefined();
  });

  it('prevents multiple reviews for the same booking by the same reviewer (FR-7.3)', async () => {
    const res = await request(app)
      .post(`/api/v1/bookings/${testBookingId}/review`)
      .set('Authorization', farmerToken)
      .send({
        rating: 4,
        comment: 'Second attempt should fail',
      });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('review_already_exists');
  });

  it('returns public reviews and calculates average rating for user (FR-7.2)', async () => {
    const res = await request(app)
      .get('/api/v1/users/11111111-0000-0000-0000-000000000001/reviews');

    expect(res.status).toBe(200);
    expect(res.body.reviewee_id).toBe('11111111-0000-0000-0000-000000000001');
    expect(res.body.average_rating).toBeGreaterThan(0);
    expect(Array.isArray(res.body.reviews)).toBe(true);
  });

  it('returns public reviews for a machine (FR-7.2)', async () => {
    const res = await request(app)
      .get('/api/v1/machines/10000000-0000-0000-0000-000000000001/reviews');

    expect(res.status).toBe(200);
    expect(res.body.machine_id).toBe('10000000-0000-0000-0000-000000000001');
    expect(res.body.average_rating).toBeGreaterThan(0);
  });

  it('admin can hide a review with required reason and recalculate averages (FR-7.4, FR-9.10, FR-9.12)', async () => {
    const targetRev = devReviews[0];
    const initialAverage = devMachines[0].average_rating;

    // Must supply reason (NFR-11)
    const badRes = await request(app)
      .patch(`/api/v1/admin/reviews/${targetRev.id}/hide`)
      .set('Authorization', adminToken)
      .send({ is_hidden: true }); // Missing reason

    expect(badRes.status).toBe(400);

    // Provide valid reason
    const hideRes = await request(app)
      .patch(`/api/v1/admin/reviews/${targetRev.id}/hide`)
      .set('Authorization', adminToken)
      .send({
        is_hidden: true,
        reason: 'Violates community standards on civility',
      });

    expect(hideRes.status).toBe(200);
    expect(hideRes.body.is_hidden).toBe(true);

    // Verify audit log has entry
    const lastAudit = devAuditLogs[0];
    expect(lastAudit.action).toBe('HIDE_REVIEW');
    expect(lastAudit.reason).toBe('Violates community standards on civility');

    // Public query should now exclude this hidden review
    const pubRes = await request(app)
      .get(`/api/v1/machines/${targetRev.machine_id}/reviews`);
    expect(pubRes.body.reviews.some((r: any) => r.id === targetRev.id)).toBe(false);
  });
});
