import { z } from 'zod';

export type SlotStatus = 'open' | 'pending' | 'booked' | 'blocked';

export interface AvailabilitySlotRecord {
  id: string;
  machine_id: string;
  slot_date: string; // YYYY-MM-DD
  start_time: string; // HH:MM or HH:MM:SS
  end_time: string; // HH:MM or HH:MM:SS
  status: SlotStatus;
  created_at: Date;
  updated_at: Date;
}

export const singleSlotSchema = z
  .object({
    slot_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'slot_date must be in YYYY-MM-DD format'),
    start_time: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/, 'start_time must be HH:MM or HH:MM:SS'),
    end_time: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/, 'end_time must be HH:MM or HH:MM:SS'),
  })
  .refine(
    (data) => data.end_time > data.start_time,
    { message: 'end_time must be after start_time', path: ['end_time'] }
  );

export const createSlotsSchema = z.object({
  slots: z.array(singleSlotSchema).min(1, 'At least one slot must be provided'),
});

export const updateSlotSchema = z.object({
  slot_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  start_time: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/).optional(),
  end_time: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/).optional(),
  status: z.enum(['open', 'pending', 'booked', 'blocked']).optional(),
  reason: z.string().optional(),
});
