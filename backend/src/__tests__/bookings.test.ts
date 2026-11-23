import request from 'supertest';
import { app } from '../app';
import * as db from '../db';
import { devSlots, devBookings } from '../models/bookingStore';
import { releaseExpiredPendingSlots } from '../jobs/releaseExpiredPendingSlots';

describe('Availability & Booking Engine (/api/v1/machines/:id/availability & /api/v1/bookings)', () => {
  const ownerToken = 'Bearer dev_owner_+94771234567'; // Sunil Perera
  const farmerToken = 'Bearer dev_farmer_+94775551122'; // Anura Kumara
  const secondFarmerToken = 'Bearer dev_farmer_+94776662233'; // Sarath Gunaratne
  const adminToken = 'Bearer dev_admin_admin@govipala.lk';

  const machineId = '10000000-0000-0000-0000-000000000001';

  beforeEach(() => {
    jest.spyOn(db, 'query').mockImplementation(async () => {
      const err: any = new Error('connect ECONNREFUSED 127.0.0.1:5432');
      err.code = 'ECONNREFUSED';
      throw err;
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Availability Slots Management (Owner)', () => {
    it('allows machine owner to publish availability slots', async () => {
      const slotsPayload = {
        slots: [
          { slot_date: '2026-11-28', start_time: '07:00:00', end_time: '12:00:00' },
          { slot_date: '2026-11-28', start_time: '13:00:00', end_time: '17:00:00' },
        ],
      };

      const res = await request(app)
        .post(`/api/v1/machines/${machineId}/availability`)
        .set('Authorization', ownerToken)
        .send(slotsPayload);

      expect(res.status).toBe(201);
      expect(res.body.created).toBe(2);
      expect(res.body.slots.length).toBe(2);
      expect(res.body.slots[0].status).toBe('open');
    });

    it('rejects slot creation with invalid time range (end_time <= start_time)', async () => {
      const invalidPayload = {
        slots: [{ slot_date: '2026-11-28', start_time: '14:00:00', end_time: '10:00:00' }],
      };

      const res = await request(app)
        .post(`/api/v1/machines/${machineId}/availability`)
        .set('Authorization', ownerToken)
        .send(invalidPayload);

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('validation_error');
    });

    it('allows anyone to fetch availability slots for a machine', async () => {
      const res = await request(app).get(`/api/v1/machines/${machineId}/availability`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);
      expect(res.body[0]).toHaveProperty('status');
      expect(res.body[0]).toHaveProperty('slot_date');
    });

    it('prevents deleting a pending or booked slot (FR-3.3)', async () => {
      // Find a slot that is pending
      const pendingSlot = devSlots.find((s) => s.status === 'pending');
      expect(pendingSlot).toBeDefined();

      const res = await request(app)
        .delete(`/api/v1/availability/${pendingSlot!.id}`)
        .set('Authorization', ownerToken);

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('cannot_delete_active_slot');
    });

    it('allows deleting an unbooked (open) slot (FR-3.2)', async () => {
      // Create a fresh open slot
      const openSlot = devSlots.find((s) => s.status === 'open' && s.machine_id === machineId);
      expect(openSlot).toBeDefined();

      const res = await request(app)
        .delete(`/api/v1/availability/${openSlot!.id}`)
        .set('Authorization', ownerToken);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('deleted');
    });
  });

  describe('Transactional Booking & Double-Booking Prevention (FR-5.2 / Architecture Sec 3)', () => {
    it('creates booking on an open slot, locking it to pending', async () => {
      // Create a dedicated open slot for this test
      const testSlotId = `test-open-slot-${Date.now()}`;
      devSlots.push({
        id: testSlotId,
        machine_id: machineId,
        slot_date: '2026-11-29',
        start_time: '08:00:00',
        end_time: '12:00:00',
        status: 'open',
        created_at: new Date(),
        updated_at: new Date(),
      });

      const bookingPayload = {
        slot_id: testSlotId,
        land_location: 'පදවිය යාය 2, අක්කර 3 කුඹුර (Padaviya Yaya 2)',
      };

      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', farmerToken)
        .send(bookingPayload);

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('requested');
      expect(res.body.slot_id).toBe(testSlotId);

      // Verify slot status in store is now pending
      const slotAfter = devSlots.find((s) => s.id === testSlotId);
      expect(slotAfter?.status).toBe('pending');
    });

    it('strictly rejects concurrent/subsequent booking request on non-open slot with 409', async () => {
      // Create a slot that is already pending
      const bookedSlotId = `test-conflict-slot-${Date.now()}`;
      devSlots.push({
        id: bookedSlotId,
        machine_id: machineId,
        slot_date: '2026-11-29',
        start_time: '13:00:00',
        end_time: '17:00:00',
        status: 'pending',
        created_at: new Date(),
        updated_at: new Date(),
      });

      const conflictPayload = {
        slot_id: bookedSlotId,
        land_location: 'පදවිය රුවන්පුර ඉඩම (Ruwanpura plot)',
      };

      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', secondFarmerToken)
        .send(conflictPayload);

      expect(res.status).toBe(409);
      expect(res.body.error).toBe('slot_no_longer_available');
    });
  });

  describe('Booking Lifecycle & Status Transitions', () => {
    it('allows owner to confirm booking, setting slot to booked (FR-5.3)', async () => {
      const targetBooking = devBookings.find((b) => b.status === 'requested');
      expect(targetBooking).toBeDefined();

      const res = await request(app)
        .patch(`/api/v1/bookings/${targetBooking!.id}/respond`)
        .set('Authorization', ownerToken)
        .send({ action: 'confirm' });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('confirmed');

      const linkedSlot = devSlots.find((s) => s.id === targetBooking!.slot_id);
      expect(linkedSlot?.status).toBe('booked');
    });

    it('allows owner or farmer to view their bookings', async () => {
      const farmerRes = await request(app)
        .get('/api/v1/bookings/mine?as=farmer')
        .set('Authorization', farmerToken);

      expect(farmerRes.status).toBe(200);
      expect(Array.isArray(farmerRes.body)).toBe(true);

      const ownerRes = await request(app)
        .get('/api/v1/bookings/mine?as=owner')
        .set('Authorization', ownerToken);

      expect(ownerRes.status).toBe(200);
      expect(Array.isArray(ownerRes.body)).toBe(true);
    });

    it('allows updating booking status to in_progress and completed', async () => {
      const confirmedBooking = devBookings.find((b) => b.status === 'confirmed');
      expect(confirmedBooking).toBeDefined();

      // Start job
      const startRes = await request(app)
        .patch(`/api/v1/bookings/${confirmedBooking!.id}/status`)
        .set('Authorization', ownerToken)
        .send({ status: 'in_progress' });

      expect(startRes.status).toBe(200);
      expect(startRes.body.status).toBe('in_progress');

      // Complete job
      const completeRes = await request(app)
        .patch(`/api/v1/bookings/${confirmedBooking!.id}/status`)
        .set('Authorization', ownerToken)
        .send({ status: 'completed' });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.status).toBe('completed');
    });

    it('re-opens availability slot when booking is cancelled with reason', async () => {
      // Setup a fresh slot and booking
      const cancelSlotId = `cancel-slot-${Date.now()}`;
      devSlots.push({
        id: cancelSlotId,
        machine_id: machineId,
        slot_date: '2026-11-30',
        start_time: '08:00:00',
        end_time: '12:00:00',
        status: 'booked',
        created_at: new Date(),
        updated_at: new Date(),
      });

      const cancelBookingId = `cancel-book-${Date.now()}`;
      devBookings.push({
        id: cancelBookingId,
        slot_id: cancelSlotId,
        farmer_id: '22222222-0000-0000-0000-000000000001',
        land_location: 'Test Plot',
        status: 'confirmed',
        created_by_admin: null,
        requested_at: new Date(),
        responded_at: new Date(),
        completed_at: null,
        cancellation_reason: null,
      });

      const res = await request(app)
        .patch(`/api/v1/bookings/${cancelBookingId}/status`)
        .set('Authorization', farmerToken)
        .send({
          status: 'cancelled',
          reason: 'Severe rain and field flooded, need to reschedule',
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('cancelled');

      // Slot must revert to open
      const slotAfter = devSlots.find((s) => s.id === cancelSlotId);
      expect(slotAfter?.status).toBe('open');
    });
  });

  describe('Expired Pending Slots Auto-Release Background Job (FR-5.4)', () => {
    it('releases pending slots back to open if owner response times out', async () => {
      const expiredSlotId = `expired-slot-${Date.now()}`;
      devSlots.push({
        id: expiredSlotId,
        machine_id: machineId,
        slot_date: '2026-11-25',
        start_time: '08:00:00',
        end_time: '12:00:00',
        status: 'pending',
        created_at: new Date(),
        updated_at: new Date(),
      });

      devBookings.push({
        id: `expired-book-${Date.now()}`,
        slot_id: expiredSlotId,
        farmer_id: '22222222-0000-0000-0000-000000000001',
        land_location: 'Timeout test plot',
        status: 'requested',
        created_by_admin: null,
        requested_at: new Date(Date.now() - 3 * 3600 * 1000), // 3 hours ago (exceeds 2 hour timeout)
        responded_at: null,
        completed_at: null,
        cancellation_reason: null,
      });

      const released = await releaseExpiredPendingSlots(2);
      expect(released).toBeGreaterThan(0);

      const slot = devSlots.find((s) => s.id === expiredSlotId);
      expect(slot?.status).toBe('open');
    });
  });

  describe('Admin Booking Management (FR-9.9 / FR-9.13)', () => {
    it('allows admin to book on behalf of a farmer with audit log', async () => {
      const adminSlotId = `admin-test-slot-${Date.now()}`;
      devSlots.push({
        id: adminSlotId,
        machine_id: machineId,
        slot_date: '2026-12-01',
        start_time: '08:00:00',
        end_time: '12:00:00',
        status: 'open',
        created_at: new Date(),
        updated_at: new Date(),
      });

      const payload = {
        farmer_id: '22222222-0000-0000-0000-000000000001',
        slot_id: adminSlotId,
        land_location: 'Farmer called DS office to book 2 acres paddy plowing',
        reason: 'Assisted phone-in reservation',
      };

      const res = await request(app)
        .post('/api/v1/admin/bookings')
        .set('Authorization', adminToken)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('requested');
      expect(res.body.created_by_admin).toBeDefined();
    });

    it('allows admin to override booking status with mandatory reason', async () => {
      const targetBooking = devBookings[0];

      const res = await request(app)
        .patch(`/api/v1/admin/bookings/${targetBooking.id}`)
        .set('Authorization', adminToken)
        .send({
          status: 'confirmed',
          reason: 'Admin resolved phone confirmation between owner and farmer',
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('confirmed');
    });
  });
});
