import { Request, Response } from 'express';
import { z } from 'zod';
import { devUsers } from '../models/userStore';
import { UserRecord } from '../middleware/auth';
import { query } from '../db';

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

const loginSchema = z.object({
  role: z.enum(['farmer', 'owner', 'machine_owner', 'admin']).transform((r) => (r === 'machine_owner' ? 'owner' : r)),
  identifier: z.string().trim().min(1, 'Phone number or email is required'),
  password: z.string().trim().min(1, 'Password is required'),
});

const directRegisterSchema = z.object({
  full_name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  role: z.enum(['farmer', 'owner', 'machine_owner', 'both']).transform((r) => (r === 'machine_owner' ? 'owner' : r)),
  phone_number: z.string().trim().min(9, 'Valid phone number is required'),
  gn_division: z.string().trim().min(1, 'GN division is required'),
  password: z.string().trim().min(4, 'Password must be at least 4 characters').optional(),
});

// Demo passwords configured per role
export const DEMO_PASSWORDS: Record<string, string[]> = {
  farmer: ['farmer123', '123456'],
  owner: ['owner123', '123456'],
  admin: ['admin123', '123456'],
};

// GET /api/v1/auth/demo-credentials
export async function getDemoCredentials(_req: Request, res: Response): Promise<void> {
  const ownerData = {
    phone: '077 123 4567',
    phone_international: '+94771234567',
    password: 'owner123',
    name: 'සුනිල් පෙරේරා (Sunil Perera)',
    gn_division: 'Padaviya Town',
  };

  res.status(200).json({
    farmer: {
      phone: '077 555 1122',
      phone_international: '+94775551122',
      password: 'farmer123',
      name: 'අනුර කුමාර (Anura Kumara)',
      gn_division: 'Padaviya East',
    },
    owner: ownerData,
    machine_owner: ownerData,
    admin: {
      email: 'admin@govipala.lk',
      phone: '077 000 0000',
      password: 'admin123',
      name: 'පරිපාලක (Govipala Admin)',
    },
  });
}

// POST /api/v1/auth/login
export async function login(req: Request, res: Response): Promise<void> {
  const parseResult = loginSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid login details.',
    });
    return;
  }

  const { role, identifier, password } = parseResult.data;

  // Validate role-specific demo password
  const validPasswords = DEMO_PASSWORDS[role] || ['123456'];
  const isPasswordValid = validPasswords.includes(password) || password === '123456';

  if (!isPasswordValid) {
    const expected = validPasswords[0];
    res.status(401).json({
      error: 'invalid_credentials',
      message: `මුරපදය වැරදියි. මෙම කාණ්ඩය සඳහා නිරූපණ මුරපදය: '${expected}' (Incorrect password. Demo password: '${expected}').`,
    });
    return;
  }

  // Format clean phone number if numeric
  const cleanNumber = identifier.replace(/\D/g, '');
  const formattedPhone = cleanNumber.length >= 9
    ? (cleanNumber.startsWith('94') ? `+${cleanNumber}` : `+94${cleanNumber.replace(/^0/, '')}`)
    : identifier;

  // 1. Admin login
  if (role === 'admin') {
    const adminUser = devUsers.find((u) => u.role === 'admin') || {
      id: '99999999-0000-0000-0000-000000000001',
      firebase_uid: 'uid_admin_001',
      phone_number: '+94770000000',
      email: 'admin@govipala.lk',
      full_name: 'පරිපාලක (Govipala Admin)',
      role: 'admin' as const,
      gn_division: 'Padaviya Town',
      preferred_lang: 'si' as const,
      status: 'active' as const,
      created_at: new Date('2026-11-20'),
      updated_at: new Date('2026-11-20'),
    };

    res.status(200).json({
      token: 'dev_admin',
      user: adminUser,
      message: 'පරිපාලක ලෙස සාර්ථකව පිවිසුණි (Logged in as Admin).',
    });
    return;
  }

  // 2. Farmer or Owner login
  let user: UserRecord | undefined = devUsers.find(
    (u) => (u.phone_number === formattedPhone || u.phone_number === identifier) &&
           (u.role === role || u.role === 'both')
  );

  if (!user) {
    // If phone didn't strictly match, fall back to first user of that role in dev mode
    user = devUsers.find((u) => u.role === role || u.role === 'both');
  }

  if (!user) {
    // Create new dev user on the fly if not found
    user = {
      id: `dev-user-${Date.now()}`,
      firebase_uid: `uid_${role}_${Date.now()}`,
      phone_number: formattedPhone,
      email: null,
      full_name: role === 'owner' ? 'යන්ත්‍ර හිමිකරු (Owner)' : 'ගොවි මහතා (Farmer)',
      role: role as 'owner' | 'farmer',
      gn_division: 'Padaviya Town',
      preferred_lang: 'si',
      status: 'active',
      created_at: new Date(),
      updated_at: new Date(),
    };
    devUsers.unshift(user);
  }

  const token = `dev_${role}_${user.phone_number || identifier}`;

  res.status(200).json({
    token,
    user,
    message: `${role === 'owner' ? 'යන්ත්‍ර හිමිකරු' : 'ගොවි'} ලෙස සාර්ථකව පිවිසුණි (Logged in successfully).`,
  });
}

// POST /api/v1/auth/register
export async function directRegister(req: Request, res: Response): Promise<void> {
  const parseResult = directRegisterSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid registration data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { full_name, role, phone_number, gn_division } = parseResult.data;

  // Clean phone number
  const cleanNumber = phone_number.replace(/\D/g, '');
  const formattedPhone = cleanNumber.startsWith('94')
    ? `+${cleanNumber}`
    : `+94${cleanNumber.replace(/^0/, '')}`;

  // Check if phone already registered in devUsers
  const existing = devUsers.find((u) => u.phone_number === formattedPhone);
  if (existing) {
    res.status(409).json({
      error: 'user_already_exists',
      message: 'මෙම දුරකථන අංකය දැනටමත් ලියාපදිංචි කර ඇත (This phone number is already registered).',
    });
    return;
  }

  const newUser: UserRecord = {
    id: `dev-user-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    firebase_uid: `uid_${role}_${Date.now()}`,
    phone_number: formattedPhone,
    email: null,
    full_name,
    role,
    gn_division,
    preferred_lang: 'si',
    status: 'active',
    created_at: new Date(),
    updated_at: new Date(),
  };

  devUsers.unshift(newUser);

  // Try DB insert if available
  try {
    await query(
      `INSERT INTO users (id, firebase_uid, phone_number, full_name, role, gn_division, preferred_lang, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now(), now())`,
      [newUser.id, newUser.firebase_uid, newUser.phone_number, newUser.full_name, newUser.role, newUser.gn_division, newUser.preferred_lang, newUser.status]
    );
  } catch (err: any) {
    if (!isDbConnectionError(err)) {
      console.warn('DB user insert warning:', err);
    }
  }

  const token = `dev_${role === 'both' ? 'farmer' : role}_${formattedPhone}`;

  res.status(201).json({
    token,
    user: newUser,
    message: 'ගිණුම සාර්ථකව සාදන ලදී (Account created successfully).',
  });
}
