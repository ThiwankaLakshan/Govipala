import { z } from 'zod';

export const createReviewSchema = z.object({
  rating: z.number().int().min(1, 'Rating must be at least 1 star').max(5, 'Rating cannot exceed 5 stars'),
  comment: z.string().trim().max(1000).optional().nullable(),
});

export const hideReviewSchema = z.object({
  is_hidden: z.boolean().default(true),
  reason: z.string().trim().min(3, 'A reason is required to hide a review'),
});

export interface ReviewRecord {
  id: string;
  booking_id: string;
  reviewer_id: string;
  reviewer_name?: string;
  reviewee_id: string;
  machine_id?: string;
  rating: number; // 1 - 5
  comment: string | null;
  is_hidden: boolean;
  created_at: Date;
}
