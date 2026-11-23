import { Router, Request, Response } from 'express';

const router = Router();

// Padaviya GN divisions seeded as reference options for registration and machine filters
export const PADAVIYA_GN_DIVISIONS = [
  'Padaviya Town',
  'Sripura',
  'Buddhangala',
  'Parakramapura',
  'Ruwanpura',
  'Sudarshanagama',
  'Jayanthiwewa',
  'Mahasenpura',
  'Abhayapura',
  'Bogahawewa',
  'Kahatagollewa',
];

router.get('/gn-divisions', (_req: Request, res: Response) => {
  res.status(200).json({
    ds_division: 'Padaviya',
    district: 'Anuradhapura',
    gn_divisions: PADAVIYA_GN_DIVISIONS,
  });
});

export default router;
