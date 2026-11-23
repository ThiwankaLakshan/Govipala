import { AvailabilitySlotRecord } from './availability';
import { BookingRecord } from './booking';

// Helper to format date YYYY-MM-DD
function getDateOffset(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().split('T')[0];
}

export const devSlots: AvailabilitySlotRecord[] = [
  // Slots for Machine 1 (Massey Ferguson 4WD Tractor - Sunil Perera)
  {
    id: 's0000000-0000-0000-0000-000000000001',
    machine_id: '10000000-0000-0000-0000-000000000001',
    slot_date: getDateOffset(0), // Today
    start_time: '07:00:00',
    end_time: '12:00:00',
    status: 'pending',
    created_at: new Date(),
    updated_at: new Date(),
  },
  {
    id: 's0000000-0000-0000-0000-000000000002',
    machine_id: '10000000-0000-0000-0000-000000000001',
    slot_date: getDateOffset(0), // Today
    start_time: '13:00:00',
    end_time: '17:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },
  {
    id: 's0000000-0000-0000-0000-000000000003',
    machine_id: '10000000-0000-0000-0000-000000000001',
    slot_date: getDateOffset(1), // Tomorrow
    start_time: '07:00:00',
    end_time: '12:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },
  {
    id: 's0000000-0000-0000-0000-000000000004',
    machine_id: '10000000-0000-0000-0000-000000000001',
    slot_date: getDateOffset(1),
    start_time: '13:00:00',
    end_time: '17:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },
  {
    id: 's0000000-0000-0000-0000-000000000005',
    machine_id: '10000000-0000-0000-0000-000000000001',
    slot_date: getDateOffset(2),
    start_time: '07:00:00',
    end_time: '12:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },

  // Slots for Machine 2 (Kubota Harvester - Kamal Silva)
  {
    id: 's0000000-0000-0000-0000-000000000006',
    machine_id: '10000000-0000-0000-0000-000000000002',
    slot_date: getDateOffset(1),
    start_time: '08:00:00',
    end_time: '16:00:00',
    status: 'booked',
    created_at: new Date(),
    updated_at: new Date(),
  },
  {
    id: 's0000000-0000-0000-0000-000000000007',
    machine_id: '10000000-0000-0000-0000-000000000002',
    slot_date: getDateOffset(2),
    start_time: '08:00:00',
    end_time: '16:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },

  // Slots for Machine 3 (Tafe 2WD Tractor - Nimal Bandara)
  {
    id: 's0000000-0000-0000-0000-000000000008',
    machine_id: '10000000-0000-0000-0000-000000000003',
    slot_date: getDateOffset(0),
    start_time: '07:30:00',
    end_time: '12:30:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },

  // Slots for Machine 4 (Mitsubishi 2WT - Priyantha Ranaweera)
  {
    id: 's0000000-0000-0000-0000-000000000009',
    machine_id: '10000000-0000-0000-0000-000000000004',
    slot_date: getDateOffset(1),
    start_time: '07:00:00',
    end_time: '13:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },

  // Slots for Machine 5 (Honda Water Pump - Chandrasena Amarasinghe)
  {
    id: 's0000000-0000-0000-0000-000000000010',
    machine_id: '10000000-0000-0000-0000-000000000005',
    slot_date: getDateOffset(0),
    start_time: '06:00:00',
    end_time: '18:00:00',
    status: 'open',
    created_at: new Date(),
    updated_at: new Date(),
  },
];

export const devBookings: BookingRecord[] = [
  // 1. Pending request from farmer Anura Kumara to Sunil Perera
  {
    id: 'b0000000-0000-0000-0000-000000000001',
    slot_id: 's0000000-0000-0000-0000-000000000001',
    farmer_id: '22222222-0000-0000-0000-000000000001', // Anura Kumara
    land_location: 'පදවිය වැව අසල කුඹුර, අක්කර 2.5 (Near Padaviya Tank)',
    status: 'requested',
    created_by_admin: null,
    requested_at: new Date(Date.now() - 30 * 60 * 1000), // 30 mins ago
    responded_at: null,
    completed_at: null,
    cancellation_reason: null,
    farmer_name: 'අනුර කුමාර (Anura Kumara)',
    farmer_phone: '+94775551122',
    farmer_gn_division: 'Padaviya East',
    owner_id: '11111111-0000-0000-0000-000000000001',
    owner_name: 'සුනිල් පෙරේරා (Sunil Perera)',
    owner_phone: '+94771234567',
    machine_id: '10000000-0000-0000-0000-000000000001',
    machine_brand: 'Massey Ferguson',
    machine_model: '240 Di',
    machine_type: 'four_wheel_tractor',
    drive_type: '4wd',
    rate_amount: 3500,
    rate_unit: 'hour',
  },

  // 2. Confirmed booking from farmer Sarath Gunaratne to Kamal Silva
  {
    id: 'b0000000-0000-0000-0000-000000000002',
    slot_id: 's0000000-0000-0000-0000-000000000006',
    farmer_id: '22222222-0000-0000-0000-000000000002', // Sarath Gunaratne
    land_location: 'ශ්‍රීපුර යාය 3, අක්කර 4 කුඹුරු ඉඩම (Sripura Yaya 3)',
    status: 'confirmed',
    created_by_admin: null,
    requested_at: new Date(Date.now() - 4 * 3600 * 1000),
    responded_at: new Date(Date.now() - 2 * 3600 * 1000),
    completed_at: null,
    cancellation_reason: null,
    farmer_name: 'සරත් ගුණරත්න (Sarath Gunaratne)',
    farmer_phone: '+94776662233',
    farmer_gn_division: 'Ruwanpura',
    owner_id: '11111111-0000-0000-0000-000000000002',
    owner_name: 'කමල් ද සිල්වා (Kamal Silva)',
    owner_phone: '+94772345678',
    machine_id: '10000000-0000-0000-0000-000000000002',
    machine_brand: 'Kubota',
    machine_model: 'DC-70G',
    machine_type: 'combine_harvester',
    drive_type: null,
    rate_amount: 9500,
    rate_unit: 'acre',
  },
];
