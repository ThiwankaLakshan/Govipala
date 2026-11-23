import { z } from 'zod';

export type MachineType =
  | 'four_wheel_tractor'
  | 'two_wheel_tractor'
  | 'combine_harvester'
  | 'water_pump';

export type DriveType = '2wd' | '4wd';
export type RateUnit = 'hour' | 'day' | 'acre';

export interface MachineRecord {
  id: string;
  owner_id: string;
  machine_type: MachineType;
  brand: string;
  drive_type: DriveType | null;
  model_name: string | null;
  rate_amount: number;
  rate_unit: RateUnit;
  photo_url: string | null;
  service_gn_divisions: string[];
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
  // Joins
  owner_name?: string;
  owner_phone?: string;
  owner_gn_division?: string;
  average_rating?: number;
  review_count?: number;
}

export const createMachineSchema = z
  .object({
    machine_type: z.enum([
      'four_wheel_tractor',
      'two_wheel_tractor',
      'combine_harvester',
      'water_pump',
    ]),
    brand: z
      .string()
      .trim()
      .min(1, 'Brand is required')
      .max(80, 'Brand must be 80 characters or less'),
    drive_type: z.enum(['2wd', '4wd']).optional().nullable(),
    model_name: z.string().trim().max(100).optional().nullable(),
    rate_amount: z.coerce.number().positive('Rate must be greater than zero'),
    rate_unit: z.enum(['hour', 'day', 'acre']),
    photo_url: z.string().url().optional().nullable().or(z.literal('')),
    service_gn_divisions: z
      .array(z.string().trim().min(1))
      .min(1, 'At least one service GN division is required'),
  })
  .superRefine((data, ctx) => {
    if (data.machine_type === 'four_wheel_tractor') {
      if (!data.drive_type) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['drive_type'],
          message: 'drive_type_required',
        });
      }
    } else {
      if (data.drive_type) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['drive_type'],
          message: 'drive_type_not_allowed',
        });
      }
    }
  });

export const updateMachineSchema = z
  .object({
    machine_type: z
      .enum([
        'four_wheel_tractor',
        'two_wheel_tractor',
        'combine_harvester',
        'water_pump',
      ])
      .optional(),
    brand: z
      .string()
      .trim()
      .min(1, 'Brand is required')
      .max(80, 'Brand must be 80 characters or less')
      .optional(),
    drive_type: z.enum(['2wd', '4wd']).optional().nullable(),
    model_name: z.string().trim().max(100).optional().nullable(),
    rate_amount: z.coerce.number().positive().optional(),
    rate_unit: z.enum(['hour', 'day', 'acre']).optional(),
    photo_url: z.string().url().optional().nullable().or(z.literal('')),
    service_gn_divisions: z.array(z.string().trim().min(1)).min(1).optional(),
    is_active: z.boolean().optional(),
  });
