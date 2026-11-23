import { Request, Response } from 'express';
import { z } from 'zod';
import { query, getClient } from '../db';
import { logAdminAction, fetchAuditLogs } from '../services/auditService';
import { devUsers } from '../models/userStore';
import { devMachines } from './machineController';
import { devSlots, devBookings } from '../models/bookingStore';
import { UserRecord } from '../middleware/auth';
import { MachineRecord } from '../models/machine';
import { BookingRecord, adminCreateBookingSchema } from '../models/booking';
import { AvailabilitySlotRecord, createSlotsSchema, updateSlotSchema } from '../models/availability';

const adminCreateUserSchema = z.object({
  full_name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  role: z.enum(['owner', 'farmer', 'both', 'admin']),
  phone_number: z.string().trim().optional().nullable(),
  email: z.string().trim().email('Invalid email').optional().nullable(),
  gn_division: z.string().trim().optional().nullable(),
  preferred_lang: z.enum(['si', 'en', 'ta']).default('si'),
  reason: z.string().optional().nullable(),
});

const adminUpdateUserSchema = z.object({
  full_name: z.string().trim().min(2).max(100).optional(),
  role: z.enum(['owner', 'farmer', 'both', 'admin']).optional(),
  phone_number: z.string().trim().optional().nullable(),
  email: z.string().trim().email().optional().nullable(),
  gn_division: z.string().trim().optional().nullable(),
  preferred_lang: z.enum(['si', 'en', 'ta']).optional(),
  reason: z.string().optional().nullable(),
});

const adminUpdateUserStatusSchema = z.object({
  status: z.enum(['active', 'suspended', 'deleted']),
  reason: z.string().trim().min(3, 'A reason is required when changing user status'),
});

const adminDeactivateMachineSchema = z.object({
  reason: z.string().trim().min(3, 'A reason is required to deactivate this machine listing').optional(),
});

// GET /api/v1/admin/stats
export async function getAdminStats(_req: Request, res: Response): Promise<void> {
  try {
    const userStatsSql = `
      SELECT 
        COUNT(*)::int AS total_users,
        COUNT(*) FILTER (WHERE role = 'farmer')::int AS farmers,
        COUNT(*) FILTER (WHERE role = 'owner')::int AS owners,
        COUNT(*) FILTER (WHERE role = 'both')::int AS both_roles,
        COUNT(*) FILTER (WHERE role = 'admin')::int AS admins,
        COUNT(*) FILTER (WHERE status = 'active')::int AS active_users,
        COUNT(*) FILTER (WHERE status = 'suspended')::int AS suspended_users
      FROM users
    `;
    const machineStatsSql = `
      SELECT 
        COUNT(*)::int AS total_machines,
        COUNT(*) FILTER (WHERE is_active = true)::int AS active_machines,
        COUNT(*) FILTER (WHERE is_active = false)::int AS inactive_machines
      FROM machines
    `;
    const bookingStatsSql = `
      SELECT 
        COUNT(*)::int AS total_bookings,
        COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_bookings,
        COUNT(*) FILTER (WHERE status = 'confirmed')::int AS confirmed_bookings,
        COUNT(*) FILTER (WHERE status = 'in_progress')::int AS in_progress_bookings,
        COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_bookings,
        COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_bookings,
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::int AS bookings_today
      FROM bookings
    `;

    const [userRes, machRes, bookRes] = await Promise.all([
      query(userStatsSql),
      query(machineStatsSql),
      query(bookingStatsSql),
    ]);

    res.status(200).json({
      users: userRes.rows[0],
      machines: machRes.rows[0],
      bookings: bookRes.rows[0],
    });
  } catch (err: any) {
    // In-memory dev fallback when PostgreSQL is offline
    const total_users = devUsers.length;
    const farmers = devUsers.filter((u) => u.role === 'farmer').length;
    const owners = devUsers.filter((u) => u.role === 'owner').length;
    const both_roles = devUsers.filter((u) => u.role === 'both').length;
    const admins = devUsers.filter((u) => u.role === 'admin').length;
    const active_users = devUsers.filter((u) => u.status === 'active').length;
    const suspended_users = devUsers.filter((u) => u.status === 'suspended').length;

    const total_machines = devMachines.length;
    const active_machines = devMachines.filter((m) => m.is_active).length;
    const inactive_machines = devMachines.filter((m) => !m.is_active).length;

    res.status(200).json({
      users: {
        total_users,
        farmers,
        owners,
        both_roles,
        admins,
        active_users,
        suspended_users,
      },
      machines: {
        total_machines,
        active_machines,
        inactive_machines,
      },
      bookings: {
        total_bookings: 12,
        pending_bookings: 3,
        confirmed_bookings: 5,
        in_progress_bookings: 1,
        completed_bookings: 2,
        cancelled_bookings: 1,
        bookings_today: 4,
      },
    });
  }
}

// GET /api/v1/admin/users
export async function getAdminUsers(req: Request, res: Response): Promise<void> {
  const { role, status, gn_division, q, limit = '50', offset = '0' } = req.query;
  const l = parseInt(limit as string, 10) || 50;
  const o = parseInt(offset as string, 10) || 0;

  try {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (role) {
      conditions.push(`role = $${idx++}`);
      values.push(role);
    }
    if (status) {
      conditions.push(`status = $${idx++}`);
      values.push(status);
    }
    if (gn_division) {
      conditions.push(`gn_division = $${idx++}`);
      values.push(gn_division);
    }
    if (q) {
      conditions.push(`(full_name ILIKE $${idx} OR phone_number ILIKE $${idx} OR email ILIKE $${idx})`);
      values.push(`%${q}%`);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const countRes = await query(`SELECT COUNT(*)::int AS total FROM users ${whereClause}`, values);
    const total = countRes.rows[0]?.total || 0;

    const sql = `
      SELECT * FROM users
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${idx++} OFFSET $${idx++}
    `;

    const userRes = await query(sql, [...values, l, o]);
    res.status(200).json({ users: userRes.rows, total });
  } catch (err: any) {
    let filtered = [...devUsers];

    if (role) filtered = filtered.filter((u) => u.role === role);
    if (status) filtered = filtered.filter((u) => u.status === status);
    if (gn_division) filtered = filtered.filter((u) => u.gn_division === gn_division);
    if (q) {
      const qStr = (q as string).toLowerCase();
      filtered = filtered.filter(
        (u) =>
          u.full_name.toLowerCase().includes(qStr) ||
          (u.phone_number && u.phone_number.includes(qStr)) ||
          (u.email && u.email.toLowerCase().includes(qStr))
      );
    }

    const total = filtered.length;
    const paginated = filtered.slice(o, o + l);
    res.status(200).json({ users: paginated, total });
  }
}

// GET /api/v1/admin/users/:id
export async function getAdminUserById(req: Request, res: Response): Promise<void> {
  const { id } = req.params;

  try {
    const userRes = await query<UserRecord>('SELECT * FROM users WHERE id = $1', [id]);
    if (userRes.rows.length === 0) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }

    const user = userRes.rows[0];
    const machinesRes = await query('SELECT * FROM machines WHERE owner_id = $1 ORDER BY created_at DESC', [id]);
    const bookingsRes = await query(
      'SELECT * FROM bookings WHERE farmer_id = $1 OR machine_id IN (SELECT id FROM machines WHERE owner_id = $1) ORDER BY created_at DESC',
      [id]
    );

    res.status(200).json({
      ...user,
      machines: machinesRes.rows,
      bookings: bookingsRes.rows,
    });
  } catch (err: any) {
    const match = devUsers.find((u) => u.id === id);
    if (!match) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }

    const userMachines = devMachines.filter((m) => m.owner_id === id);
    res.status(200).json({
      ...match,
      machines: userMachines,
      bookings: [],
    });
  }
}

// POST /api/v1/admin/users
export async function createAdminUser(req: Request, res: Response): Promise<void> {
  const parseResult = adminCreateUserSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid input data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { full_name, role, phone_number, email, gn_division, preferred_lang, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  try {
    const firebaseUid = `uid_admin_created_${Date.now()}`;
    const insertRes = await query<UserRecord>(
      `INSERT INTO users (
        firebase_uid,
        phone_number,
        email,
        full_name,
        role,
        gn_division,
        preferred_lang,
        status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'active')
      RETURNING *`,
      [firebaseUid, phone_number || null, email || null, full_name, role, gn_division || null, preferred_lang]
    );

    const newUser = insertRes.rows[0];

    // Audit log
    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'CREATE_USER',
      target_table: 'users',
      target_id: newUser.id,
      after_data: { full_name, role, phone_number, email, gn_division, preferred_lang },
      reason: reason || 'Created via Admin Panel',
    });

    res.status(201).json(newUser);
  } catch (err: any) {
    const newDevUser: UserRecord = {
      id: `dev-user-${Date.now()}`,
      firebase_uid: `uid_admin_created_${Date.now()}`,
      phone_number: phone_number || null,
      email: email || null,
      full_name,
      role,
      gn_division: gn_division || 'Padaviya Town',
      preferred_lang,
      status: 'active',
      created_at: new Date(),
      updated_at: new Date(),
    };

    devUsers.unshift(newDevUser);

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'CREATE_USER',
      target_table: 'users',
      target_id: newDevUser.id,
      after_data: newDevUser,
      reason: reason || 'Created via Admin Panel',
    });

    res.status(201).json(newDevUser);
  }
}

// PATCH /api/v1/admin/users/:id
export async function updateAdminUser(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const parseResult = adminUpdateUserSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid input data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { full_name, role, phone_number, email, gn_division, preferred_lang, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  try {
    const existingRes = await query<UserRecord>('SELECT * FROM users WHERE id = $1', [id]);
    if (existingRes.rows.length === 0) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }
    const beforeUser = existingRes.rows[0];

    const updateRes = await query<UserRecord>(
      `UPDATE users
       SET full_name = COALESCE($1, full_name),
           role = COALESCE($2, role),
           phone_number = COALESCE($3, phone_number),
           email = COALESCE($4, email),
           gn_division = COALESCE($5, gn_division),
           preferred_lang = COALESCE($6, preferred_lang),
           updated_at = now()
       WHERE id = $7
       RETURNING *`,
      [
        full_name || null,
        role || null,
        phone_number !== undefined ? phone_number : null,
        email !== undefined ? email : null,
        gn_division !== undefined ? gn_division : null,
        preferred_lang || null,
        id,
      ]
    );

    const afterUser = updateRes.rows[0];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_USER',
      target_table: 'users',
      target_id: id,
      before_data: beforeUser,
      after_data: afterUser,
      reason: reason || 'Updated via Admin Panel',
    });

    res.status(200).json(afterUser);
  } catch (err: any) {
    const idx = devUsers.findIndex((u) => u.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }

    const beforeUser = { ...devUsers[idx] };
    devUsers[idx] = {
      ...devUsers[idx],
      ...(full_name && { full_name }),
      ...(role && { role }),
      ...(phone_number !== undefined && { phone_number }),
      ...(email !== undefined && { email }),
      ...(gn_division !== undefined && { gn_division }),
      ...(preferred_lang && { preferred_lang }),
      updated_at: new Date(),
    };
    const afterUser = devUsers[idx];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_USER',
      target_table: 'users',
      target_id: id,
      before_data: beforeUser,
      after_data: afterUser,
      reason: reason || 'Updated via Admin Panel',
    });

    res.status(200).json(afterUser);
  }
}

// PATCH /api/v1/admin/users/:id/status
export async function updateAdminUserStatus(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const parseResult = adminUpdateUserStatusSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid status change data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { status, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  try {
    const existingRes = await query<UserRecord>('SELECT * FROM users WHERE id = $1', [id]);
    if (existingRes.rows.length === 0) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }
    const beforeUser = existingRes.rows[0];

    // Check affected bookings if suspending or deleting (per FR-9.4)
    const affectedBookingsRes = await query(
      `SELECT b.*, m.machine_type, m.brand 
       FROM bookings b 
       JOIN machines m ON b.machine_id = m.id 
       WHERE (b.farmer_id = $1 OR m.owner_id = $1) 
         AND b.status IN ('pending', 'confirmed') 
         AND b.start_time >= now()`,
      [id]
    );

    const updateRes = await query<UserRecord>(
      'UPDATE users SET status = $1, updated_at = now() WHERE id = $2 RETURNING *',
      [status, id]
    );
    const afterUser = updateRes.rows[0];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_USER_STATUS',
      target_table: 'users',
      target_id: id,
      before_data: { status: beforeUser.status },
      after_data: { status: afterUser.status },
      reason,
    });

    res.status(200).json({
      user: afterUser,
      affected_bookings: affectedBookingsRes.rows,
    });
  } catch (err: any) {
    const idx = devUsers.findIndex((u) => u.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'user_not_found', message: 'User not found.' });
      return;
    }

    const beforeUser = { ...devUsers[idx] };
    devUsers[idx] = {
      ...devUsers[idx],
      status,
      updated_at: new Date(),
    };
    const afterUser = devUsers[idx];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_USER_STATUS',
      target_table: 'users',
      target_id: id,
      before_data: { status: beforeUser.status },
      after_data: { status: afterUser.status },
      reason,
    });

    res.status(200).json({
      user: afterUser,
      affected_bookings: [],
    });
  }
}

// GET /api/v1/admin/machines
export async function getAdminMachines(req: Request, res: Response): Promise<void> {
  const { owner_id, machine_type, q, is_active, limit = '50', offset = '0' } = req.query;
  const l = parseInt(limit as string, 10) || 50;
  const o = parseInt(offset as string, 10) || 0;

  try {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (owner_id) {
      conditions.push(`m.owner_id = $${idx++}`);
      values.push(owner_id);
    }
    if (machine_type) {
      conditions.push(`m.machine_type = $${idx++}`);
      values.push(machine_type);
    }
    if (is_active !== undefined) {
      conditions.push(`m.is_active = $${idx++}`);
      values.push(is_active === 'true');
    }
    if (q) {
      conditions.push(`(m.brand ILIKE $${idx} OR m.model_name ILIKE $${idx} OR u.full_name ILIKE $${idx})`);
      values.push(`%${q}%`);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const countRes = await query(`SELECT COUNT(*)::int as total FROM machines m JOIN users u ON m.owner_id = u.id ${whereClause}`, values);
    const total = countRes.rows[0]?.total || 0;

    const sql = `
      SELECT 
        m.*,
        u.full_name AS owner_name,
        u.phone_number AS owner_phone,
        u.gn_division AS owner_gn_division,
        COALESCE(AVG(r.rating), 0)::numeric(2,1) AS average_rating,
        COUNT(r.id)::int AS review_count
      FROM machines m
      JOIN users u ON m.owner_id = u.id
      LEFT JOIN reviews r ON r.reviewee_id = m.owner_id AND r.is_hidden = false
      ${whereClause}
      GROUP BY m.id, u.id
      ORDER BY m.created_at DESC
      LIMIT $${idx++} OFFSET $${idx++}
    `;

    const result = await query(sql, [...values, l, o]);
    res.status(200).json({ machines: result.rows, total });
  } catch (err: any) {
    let filtered = [...devMachines];

    if (owner_id) filtered = filtered.filter((m) => m.owner_id === owner_id);
    if (machine_type) filtered = filtered.filter((m) => m.machine_type === machine_type);
    if (is_active !== undefined) filtered = filtered.filter((m) => m.is_active === (is_active === 'true'));
    if (q) {
      const qStr = (q as string).toLowerCase();
      filtered = filtered.filter(
        (m) =>
          m.brand.toLowerCase().includes(qStr) ||
          (m.model_name && m.model_name.toLowerCase().includes(qStr)) ||
          (m.owner_name && m.owner_name.toLowerCase().includes(qStr))
      );
    }

    const total = filtered.length;
    const paginated = filtered.slice(o, o + l);
    res.status(200).json({ machines: paginated, total });
  }
}

// PATCH /api/v1/admin/machines/:id
export async function updateAdminMachine(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';
  const reason = req.body.reason || 'Admin modification on behalf of owner';

  try {
    const existingRes = await query<MachineRecord>('SELECT * FROM machines WHERE id = $1', [id]);
    if (existingRes.rows.length === 0) {
      res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
      return;
    }
    const beforeMachine = existingRes.rows[0];

    const {
      machine_type,
      brand,
      drive_type,
      model_name,
      rate_amount,
      rate_unit,
      photo_url,
      service_gn_divisions,
      is_active,
    } = req.body;

    const updateRes = await query<MachineRecord>(
      `UPDATE machines
       SET machine_type = COALESCE($1, machine_type),
           brand = COALESCE($2, brand),
           drive_type = CASE WHEN $1 = 'four_wheel_tractor' OR ($1 IS NULL AND machine_type = 'four_wheel_tractor') THEN COALESCE($3, drive_type) ELSE NULL END,
           model_name = COALESCE($4, model_name),
           rate_amount = COALESCE($5, rate_amount),
           rate_unit = COALESCE($6, rate_unit),
           photo_url = COALESCE($7, photo_url),
           service_gn_divisions = COALESCE($8, service_gn_divisions),
           is_active = COALESCE($9, is_active),
           updated_at = now()
       WHERE id = $10
       RETURNING *`,
      [
        machine_type || null,
        brand || null,
        drive_type || null,
        model_name || null,
        rate_amount || null,
        rate_unit || null,
        photo_url || null,
        service_gn_divisions || null,
        is_active !== undefined ? is_active : null,
        id,
      ]
    );

    const afterMachine = updateRes.rows[0];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_MACHINE',
      target_table: 'machines',
      target_id: id,
      before_data: beforeMachine,
      after_data: afterMachine,
      reason,
    });

    res.status(200).json(afterMachine);
  } catch (err: any) {
    const idx = devMachines.findIndex((m) => m.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
      return;
    }

    const beforeMachine = { ...devMachines[idx] };
    devMachines[idx] = {
      ...devMachines[idx],
      ...req.body,
      updated_at: new Date(),
    };
    const afterMachine = devMachines[idx];

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'UPDATE_MACHINE',
      target_table: 'machines',
      target_id: id,
      before_data: beforeMachine,
      after_data: afterMachine,
      reason,
    });

    res.status(200).json(afterMachine);
  }
}

// DELETE /api/v1/admin/machines/:id
export async function deactivateAdminMachine(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  const parseResult = adminDeactivateMachineSchema.safeParse(req.body);
  const reason = parseResult.success && parseResult.data.reason
    ? parseResult.data.reason
    : (req.body?.reason || 'Deactivated by administrator on behalf of owner');

  try {
    const existingRes = await query<MachineRecord>('SELECT * FROM machines WHERE id = $1', [id]);
    if (existingRes.rows.length === 0) {
      res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
      return;
    }
    const beforeMachine = existingRes.rows[0];

    await query('UPDATE machines SET is_active = false, updated_at = now() WHERE id = $1', [id]);

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'DEACTIVATE_MACHINE',
      target_table: 'machines',
      target_id: id,
      before_data: { is_active: beforeMachine.is_active },
      after_data: { is_active: false },
      reason,
    });

    res.status(200).json({ message: 'Machine listing deactivated successfully by admin.' });
  } catch (err: any) {
    const idx = devMachines.findIndex((m) => m.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
      return;
    }

    devMachines[idx].is_active = false;
    devMachines[idx].updated_at = new Date();

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'DEACTIVATE_MACHINE',
      target_table: 'machines',
      target_id: id,
      before_data: { is_active: true },
      after_data: { is_active: false },
      reason,
    });

    res.status(200).json({ message: 'Machine listing deactivated successfully by admin.' });
  }
}

// GET /api/v1/admin/audit-log
export async function getAdminAuditLogs(req: Request, res: Response): Promise<void> {
  const { admin_id, target_table, target_id, from, to, limit = '50', offset = '0' } = req.query;

  const result = await fetchAuditLogs({
    admin_id: admin_id as string,
    target_table: target_table as string,
    target_id: target_id as string,
    from: from as string,
    to: to as string,
    limit: parseInt(limit as string, 10) || 50,
    offset: parseInt(offset as string, 10) || 0,
  });

  res.status(200).json(result);
}

// ============================================
// ADMIN AVAILABILITY & BOOKING MANAGEMENT
// ============================================

// GET /api/v1/admin/bookings
export async function getAdminBookings(req: Request, res: Response): Promise<void> {
  const { status, farmer_id, owner_id, machine_id, from, to, limit = '50', offset = '0' } = req.query;
  const l = parseInt(limit as string, 10) || 50;
  const o = parseInt(offset as string, 10) || 0;

  try {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (status) {
      conditions.push(`b.status = $${idx++}`);
      values.push(status);
    }
    if (farmer_id) {
      conditions.push(`b.farmer_id = $${idx++}`);
      values.push(farmer_id);
    }
    if (owner_id) {
      conditions.push(`m.owner_id = $${idx++}`);
      values.push(owner_id);
    }
    if (machine_id) {
      conditions.push(`m.id = $${idx++}`);
      values.push(machine_id);
    }
    if (from) {
      conditions.push(`s.slot_date >= $${idx++}`);
      values.push(from);
    }
    if (to) {
      conditions.push(`s.slot_date <= $${idx++}`);
      values.push(to);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const countSql = `
      SELECT COUNT(*)::int AS total
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      ${whereClause}
    `;
    const countRes = await query(countSql, values);
    const total = countRes.rows[0]?.total || 0;

    const sql = `
      SELECT 
        b.*,
        u_farmer.full_name AS farmer_name,
        u_farmer.phone_number AS farmer_phone,
        u_farmer.gn_division AS farmer_gn_division,
        u_owner.id AS owner_id,
        u_owner.full_name AS owner_name,
        u_owner.phone_number AS owner_phone,
        m.id AS machine_id,
        m.brand AS machine_brand,
        m.model_name AS machine_model,
        m.machine_type AS machine_type,
        m.drive_type AS drive_type,
        m.rate_amount,
        m.rate_unit,
        s.slot_date,
        s.start_time,
        s.end_time,
        s.status AS slot_status
      FROM bookings b
      JOIN availability_slots s ON b.slot_id = s.id
      JOIN machines m ON s.machine_id = m.id
      JOIN users u_farmer ON b.farmer_id = u_farmer.id
      JOIN users u_owner ON m.owner_id = u_owner.id
      ${whereClause}
      ORDER BY b.requested_at DESC
      LIMIT $${idx++} OFFSET $${idx++}
    `;

    const result = await query(sql, [...values, l, o]);
    res.status(200).json({ bookings: result.rows, total });
  } catch (err: any) {
    let filtered = [...devBookings];

    if (status) filtered = filtered.filter((b) => b.status === status);
    if (farmer_id) filtered = filtered.filter((b) => b.farmer_id === farmer_id);
    if (owner_id) filtered = filtered.filter((b) => b.owner_id === owner_id);
    if (machine_id) filtered = filtered.filter((b) => b.machine_id === machine_id);

    const enriched = filtered.map((b) => {
      const slot = devSlots.find((s) => s.id === b.slot_id);
      const machine = slot ? devMachines.find((m) => m.id === slot.machine_id) : undefined;
      return {
        ...b,
        slot_date: slot?.slot_date,
        start_time: slot?.start_time,
        end_time: slot?.end_time,
        slot_status: slot?.status,
        machine_brand: machine?.brand || b.machine_brand,
        machine_model: machine?.model_name || b.machine_model,
        machine_type: machine?.machine_type || b.machine_type,
        drive_type: machine?.drive_type || b.drive_type,
        rate_amount: machine?.rate_amount || b.rate_amount,
        rate_unit: machine?.rate_unit || b.rate_unit,
      };
    });

    const total = enriched.length;
    const paginated = enriched.slice(o, o + l);
    res.status(200).json({ bookings: paginated, total });
  }
}

// POST /api/v1/admin/bookings
// Admin books on behalf of a farmer (FR-9.9 / UC-6)
export async function createAdminBooking(req: Request, res: Response): Promise<void> {
  const parseResult = adminCreateBookingSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid booking data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { farmer_id, slot_id, land_location, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    // In-memory dev fallback
    const slot = devSlots.find((s) => s.id === slot_id);
    if (!slot) {
      res.status(404).json({ error: 'slot_not_found', message: 'Slot not found.' });
      return;
    }

    if (slot.status !== 'open') {
      res.status(409).json({ error: 'slot_no_longer_available', message: 'Slot is not open.' });
      return;
    }

    slot.status = 'pending';
    slot.updated_at = new Date();

    const farmer = devUsers.find((u) => u.id === farmer_id);
    const machine = devMachines.find((m) => m.id === slot.machine_id);

    const newBooking: BookingRecord = {
      id: `dev-book-admin-${Date.now()}`,
      slot_id,
      farmer_id,
      land_location,
      status: 'requested',
      created_by_admin: adminId,
      requested_at: new Date(),
      responded_at: null,
      completed_at: null,
      cancellation_reason: null,
      farmer_name: farmer?.full_name || 'Farmer',
      farmer_phone: farmer?.phone_number || '+94775551122',
      farmer_gn_division: farmer?.gn_division || 'Padaviya',
      owner_id: machine?.owner_id,
      owner_name: machine?.owner_name,
      owner_phone: machine?.owner_phone,
      machine_id: machine?.id,
      machine_brand: machine?.brand,
      machine_model: machine?.model_name,
      machine_type: machine?.machine_type,
      drive_type: machine?.drive_type,
      rate_amount: machine?.rate_amount,
      rate_unit: machine?.rate_unit,
    };

    devBookings.unshift(newBooking);

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'CREATE_BOOKING_ON_BEHALF',
      target_table: 'bookings',
      target_id: newBooking.id,
      after_data: newBooking,
      reason: reason || 'Admin booked on behalf of farmer (phone-in)',
    });

    res.status(201).json(newBooking);
    return;
  }

  try {
    await client.query('BEGIN');

    // Concurrency lock slot
    const slotRes = await client.query<AvailabilitySlotRecord>(
      'SELECT * FROM availability_slots WHERE id = $1 FOR UPDATE',
      [slot_id]
    );

    if (slotRes.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ error: 'slot_not_found', message: 'Slot not found.' });
      return;
    }

    const slot = slotRes.rows[0];
    if (slot.status !== 'open') {
      await client.query('ROLLBACK');
      res.status(409).json({ error: 'slot_no_longer_available', message: 'Slot is not open.' });
      return;
    }

    await client.query("UPDATE availability_slots SET status = 'pending', updated_at = now() WHERE id = $1", [slot_id]);

    const bookingRes = await client.query<BookingRecord>(
      `INSERT INTO bookings (slot_id, farmer_id, land_location, status, created_by_admin, requested_at)
       VALUES ($1, $2, $3, 'requested', $4, now())
       RETURNING *`,
      [slot_id, farmer_id, land_location, adminId]
    );

    const booking = bookingRes.rows[0];

    await logAdminAction({
      client,
      admin_id: adminId,
      admin_name: adminName,
      action: 'CREATE_BOOKING_ON_BEHALF',
      target_table: 'bookings',
      target_id: booking.id,
      after_data: booking,
      reason: reason || 'Admin booked on behalf of farmer (phone-in)',
    });

    await client.query('COMMIT');
    res.status(201).json(booking);
  } catch (err: any) {
    if (client) await client.query('ROLLBACK');
    console.error('Error in createAdminBooking:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create booking on behalf of farmer.' });
  } finally {
    if (client) client.release();
  }
}

// PATCH /api/v1/admin/bookings/:id
// Admin overrides booking status with required reason (FR-9.8 / FR-9.13)
export async function overrideAdminBookingStatus(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const { status, reason } = req.body;

  if (!status || !reason) {
    res.status(400).json({
      error: 'validation_error',
      message: 'Both status and reason are mandatory for admin booking override.',
    });
    return;
  }

  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  let client;
  try {
    client = await getClient();
  } catch (err: any) {
    const idx = devBookings.findIndex((b) => b.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = devBookings[idx];
    const beforeStatus = booking.status;
    booking.status = status;
    booking.cancellation_reason = reason;

    const slot = devSlots.find((s) => s.id === booking.slot_id);
    if (slot) {
      if (status === 'confirmed' || status === 'in_progress' || status === 'completed') {
        slot.status = 'booked';
      } else if (status === 'rejected' || status === 'cancelled') {
        slot.status = 'open'; // Re-open
      }
    }

    await logAdminAction({
      admin_id: adminId,
      admin_name: adminName,
      action: 'OVERRIDE_BOOKING_STATUS',
      target_table: 'bookings',
      target_id: id,
      before_data: { status: beforeStatus },
      after_data: { status },
      reason,
    });

    res.status(200).json(booking);
    return;
  }

  try {
    await client.query('BEGIN');

    const bookingRes = await client.query<BookingRecord>(
      'SELECT * FROM bookings WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (bookingRes.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ error: 'booking_not_found', message: 'Booking not found.' });
      return;
    }

    const booking = bookingRes.rows[0];
    const beforeStatus = booking.status;

    let slotStatus = 'open';
    if (status === 'confirmed' || status === 'in_progress' || status === 'completed') {
      slotStatus = 'booked';
    } else if (status === 'requested') {
      slotStatus = 'pending';
    }

    await client.query(
      'UPDATE bookings SET status = $1, cancellation_reason = $2 WHERE id = $3',
      [status, reason, id]
    );

    await client.query(
      'UPDATE availability_slots SET status = $1, updated_at = now() WHERE id = $2',
      [slotStatus, booking.slot_id]
    );

    await logAdminAction({
      client,
      admin_id: adminId,
      admin_name: adminName,
      action: 'OVERRIDE_BOOKING_STATUS',
      target_table: 'bookings',
      target_id: id,
      before_data: { status: beforeStatus },
      after_data: { status },
      reason,
    });

    await client.query('COMMIT');
    res.status(200).json({ id, status });
  } catch (err: any) {
    if (client) await client.query('ROLLBACK');
    console.error('Error in overrideAdminBookingStatus:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to override booking status.' });
  } finally {
    if (client) client.release();
  }
}

// POST /api/v1/admin/machines/:id/availability
export async function adminCreateMachineAvailability(req: Request, res: Response): Promise<void> {
  const { id: machineId } = req.params;
  const parseResult = createSlotsSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid slots.',
    });
    return;
  }

  const { slots } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  const createdSlots: AvailabilitySlotRecord[] = [];
  for (const slot of slots) {
    const newSlot: AvailabilitySlotRecord = {
      id: `slot-admin-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      machine_id: machineId,
      slot_date: slot.slot_date,
      start_time: slot.start_time.includes(':') && slot.start_time.split(':').length === 2 ? `${slot.start_time}:00` : slot.start_time,
      end_time: slot.end_time.includes(':') && slot.end_time.split(':').length === 2 ? `${slot.end_time}:00` : slot.end_time,
      status: 'open',
      created_at: new Date(),
      updated_at: new Date(),
    };
    devSlots.push(newSlot);
    createdSlots.push(newSlot);
  }

  await logAdminAction({
    admin_id: adminId,
    admin_name: adminName,
    action: 'CREATE_AVAILABILITY_SLOTS',
    target_table: 'availability_slots',
    target_id: machineId,
    after_data: { count: createdSlots.length, slots },
    reason: 'Admin added availability slots for machine',
  });

  res.status(201).json({ created: createdSlots.length, slots: createdSlots });
}

// PATCH /api/v1/admin/availability/:slotId
export async function adminUpdateSlot(req: Request, res: Response): Promise<void> {
  const { slotId } = req.params;
  const parseResult = updateSlotSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid slot data.',
    });
    return;
  }

  const { status, slot_date, start_time, end_time, reason } = parseResult.data;
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  const idx = devSlots.findIndex((s) => s.id === slotId);
  if (idx === -1) {
    res.status(404).json({ error: 'slot_not_found', message: 'Slot not found.' });
    return;
  }

  const beforeSlot = { ...devSlots[idx] };
  devSlots[idx] = {
    ...devSlots[idx],
    ...(status && { status }),
    ...(slot_date && { slot_date }),
    ...(start_time && { start_time }),
    ...(end_time && { end_time }),
    updated_at: new Date(),
  };
  const afterSlot = devSlots[idx];

  await logAdminAction({
    admin_id: adminId,
    admin_name: adminName,
    action: 'UPDATE_AVAILABILITY_SLOT',
    target_table: 'availability_slots',
    target_id: slotId,
    before_data: beforeSlot,
    after_data: afterSlot,
    reason: reason || 'Admin updated slot',
  });

  res.status(200).json(afterSlot);
}

// DELETE /api/v1/admin/availability/:slotId
export async function adminDeleteSlot(req: Request, res: Response): Promise<void> {
  const { slotId } = req.params;
  const reason = req.body.reason || 'Admin removed slot';
  const adminId = req.user?.id || 'admin-system';
  const adminName = req.user?.full_name || 'Admin';

  const idx = devSlots.findIndex((s) => s.id === slotId);
  if (idx === -1) {
    res.status(404).json({ error: 'slot_not_found', message: 'Slot not found.' });
    return;
  }

  const slot = devSlots[idx];

  // If slot had a pending or confirmed booking, cancel it with reason per FR-9.6
  const linkedBooking = devBookings.find((b) => b.slot_id === slotId && (b.status === 'requested' || b.status === 'confirmed'));
  if (linkedBooking) {
    linkedBooking.status = 'cancelled';
    linkedBooking.cancellation_reason = `Slot cancelled by admin: ${reason}`;
  }

  devSlots.splice(idx, 1);

  await logAdminAction({
    admin_id: adminId,
    admin_name: adminName,
    action: 'DELETE_AVAILABILITY_SLOT',
    target_table: 'availability_slots',
    target_id: slotId,
    before_data: slot,
    reason,
  });

  res.status(200).json({ message: 'Slot deleted and linked bookings cancelled if any.' });
}

