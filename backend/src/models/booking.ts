import { z } from 'zod';
import { AvailabilitySlotRecord } from './availability';
import { MachineRecord } from './machine';

export type BookingStatus =
  | 'requested'
  | 'confirmed'
  | 'rejected'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export interface BookingRecord {
  id: string;
  slot_id: string;
  farmer_id: string;
  land_location: string | null;
  status: BookingStatus;
  created_by_admin: string | null;
  requested_at: Date;
  responded_at: Date | null;
  completed_at: Date | null;
  cancellation_reason: string | null;

  // Joined fields for display
  farmer_name?: string;
  farmer_phone?: string;
  farmer_gn_division?: string;
  owner_id?: string;
  owner_name?: string;
  owner_phone?: string;
  machine_id?: string;
  machine_brand?: string;
  machine_model?: string | null;
  machine_type?: string;
  drive_type?: string | null;
  rate_amount?: number;
  rate_unit?: string;
  slot?: AvailabilitySlotRecord;
  machine?: MachineRecord;
}

export const createBookingSchema = z.object({
  slot_id: z.string().min(1, 'Slot ID is required'),
  land_location: z.string().trim().min(3, 'Please describe land location or GN division').max(500),
});

export const respondBookingSchema = z.object({
  action: z.enum(['confirm', 'reject']),
  reason: z.string().optional(),
});

export const updateBookingStatusSchema = z.object({
  status: z.enum(['in_progress', 'completed', 'cancelled']),
  reason: z.string().optional(),
});

export const adminCreateBookingSchema = z.object({
  farmer_id: z.string().min(1, 'Farmer ID is required'),
  slot_id: z.string().min(1, 'Slot ID is required'),
  land_location: z.string().trim().min(3, 'Please describe land location').max(500),
  reason: z.string().optional(),
});
