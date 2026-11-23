import { Request, Response } from 'express';
import { query } from '../db';
import {
  createMachineSchema,
  updateMachineSchema,
  MachineRecord,
} from '../models/machine';

// In-memory fallback dataset for development when PostgreSQL is not connected
export const devMachines: MachineRecord[] = [
  {
    id: '10000000-0000-0000-0000-000000000001',
    owner_id: '11111111-0000-0000-0000-000000000001',
    machine_type: 'four_wheel_tractor',
    brand: 'Massey Ferguson',
    drive_type: '4wd',
    model_name: '240 Di',
    rate_amount: 3500,
    rate_unit: 'hour',
    photo_url: null,
    service_gn_divisions: ['Padaviya Town', 'Sripura', 'Buddhangala'],
    is_active: true,
    created_at: new Date('2026-11-20'),
    updated_at: new Date('2026-11-20'),
    owner_name: 'සුනිල් පෙරේරා (Sunil Perera)',
    owner_phone: '+94771234567',
    owner_gn_division: 'Padaviya Town',
    average_rating: 4.8,
    review_count: 7,
  },
  {
    id: '10000000-0000-0000-0000-000000000002',
    owner_id: '11111111-0000-0000-0000-000000000002',
    machine_type: 'combine_harvester',
    brand: 'Kubota',
    drive_type: null,
    model_name: 'DC-70G',
    rate_amount: 9500,
    rate_unit: 'acre',
    photo_url: null,
    service_gn_divisions: ['Sripura', 'Buddhangala', 'Parakramapura'],
    is_active: true,
    created_at: new Date('2026-11-21'),
    updated_at: new Date('2026-11-21'),
    owner_name: 'කමල් ද සිල්වා (Kamal Silva)',
    owner_phone: '+94772345678',
    owner_gn_division: 'Sripura',
    average_rating: 4.9,
    review_count: 14,
  },
  {
    id: '10000000-0000-0000-0000-000000000003',
    owner_id: '11111111-0000-0000-0000-000000000003',
    machine_type: 'four_wheel_tractor',
    brand: 'Tafe',
    drive_type: '2wd',
    model_name: '45 DI',
    rate_amount: 3200,
    rate_unit: 'hour',
    photo_url: null,
    service_gn_divisions: ['Buddhangala', 'Parakramapura', 'Ruwanpura'],
    is_active: true,
    created_at: new Date('2026-11-22'),
    updated_at: new Date('2026-11-22'),
    owner_name: 'නිමල් බණ්ඩාර (Nimal Bandara)',
    owner_phone: '+94773456789',
    owner_gn_division: 'Buddhangala',
    average_rating: 4.6,
    review_count: 5,
  },
  {
    id: '10000000-0000-0000-0000-000000000004',
    owner_id: '11111111-0000-0000-0000-000000000004',
    machine_type: 'two_wheel_tractor',
    brand: 'Mitsubishi',
    drive_type: null,
    model_name: 'CT 83',
    rate_amount: 1800,
    rate_unit: 'hour',
    photo_url: null,
    service_gn_divisions: ['Padaviya Town', 'Parakramapura'],
    is_active: true,
    created_at: new Date('2026-11-22'),
    updated_at: new Date('2026-11-22'),
    owner_name: 'ප්‍රියන්ත රණවීර (Priyantha Ranaweera)',
    owner_phone: '+94774567890',
    owner_gn_division: 'Parakramapura',
    average_rating: 4.7,
    review_count: 9,
  },
  {
    id: '10000000-0000-0000-0000-000000000005',
    owner_id: '11111111-0000-0000-0000-000000000005',
    machine_type: 'water_pump',
    brand: 'Honda',
    drive_type: null,
    model_name: 'WB30XT',
    rate_amount: 1200,
    rate_unit: 'day',
    photo_url: null,
    service_gn_divisions: ['Sripura', 'Ruwanpura', 'Jayanthiwewa', 'Padaviya Town'],
    is_active: true,
    created_at: new Date('2026-11-23'),
    updated_at: new Date('2026-11-23'),
    owner_name: 'චන්ද්‍රසේන අමරසිංහ (Chandrasena Amarasinghe)',
    owner_phone: '+94775678901',
    owner_gn_division: 'Ruwanpura',
    average_rating: 5.0,
    review_count: 3,
  },
];

export async function createMachine(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  if (req.user.role !== 'owner' && req.user.role !== 'both' && req.user.role !== 'admin') {
    res.status(403).json({
      error: 'owner_only',
      message: 'Only registered machine owners can add machine listings.',
    });
    return;
  }

  const parseResult = createMachineSchema.safeParse(req.body);
  if (!parseResult.success) {
    const firstIssue = parseResult.error.issues[0];
    if (firstIssue.message === 'drive_type_required') {
      res.status(400).json({
        error: 'drive_type_required',
        message: 'A drive type (2WD or 4WD) is required for four-wheel tractors.',
      });
      return;
    }
    if (firstIssue.message === 'drive_type_not_allowed') {
      res.status(400).json({
        error: 'drive_type_not_allowed',
        message: 'Drive type can only be specified for four-wheel tractors.',
      });
      return;
    }
    res.status(400).json({
      error: 'validation_error',
      message: firstIssue.message || 'Invalid machine data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const {
    machine_type,
    brand,
    drive_type,
    model_name,
    rate_amount,
    rate_unit,
    photo_url,
    service_gn_divisions,
  } = parseResult.data;

  try {
    const result = await query<MachineRecord>(
      `INSERT INTO machines (
        owner_id,
        machine_type,
        brand,
        drive_type,
        model_name,
        rate_amount,
        rate_unit,
        photo_url,
        service_gn_divisions,
        is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true)
      RETURNING *`,
      [
        req.user.id,
        machine_type,
        brand,
        drive_type || null,
        model_name || null,
        rate_amount,
        rate_unit,
        photo_url || null,
        service_gn_divisions,
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err: any) {
    // If PostgreSQL is not connected, handle in-memory fallback for development
    if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
      const newMachine: MachineRecord = {
        id: `dev-mach-${Date.now()}`,
        owner_id: req.user.id,
        machine_type,
        brand,
        drive_type: drive_type || null,
        model_name: model_name || null,
        rate_amount,
        rate_unit,
        photo_url: photo_url || null,
        service_gn_divisions,
        is_active: true,
        created_at: new Date(),
        updated_at: new Date(),
        owner_name: req.user.full_name,
        owner_phone: req.user.phone_number || '+94771234567',
        owner_gn_division: req.user.gn_division || 'Padaviya Town',
        average_rating: 0,
        review_count: 0,
      };
      devMachines.unshift(newMachine);
      res.status(201).json(newMachine);
      return;
    }

    console.error('Error creating machine:', err);
    res.status(500).json({
      error: 'server_error',
      message: 'Failed to create machine listing.',
    });
  }
}

export async function getMachines(req: Request, res: Response): Promise<void> {
  const { machine_type, gn_division, owner_id, is_active } = req.query;

  try {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (is_active !== undefined) {
      conditions.push(`m.is_active = $${idx++}`);
      values.push(is_active === 'true');
    } else {
      conditions.push(`m.is_active = true`);
    }

    if (machine_type) {
      conditions.push(`m.machine_type = $${idx++}`);
      values.push(machine_type);
    }

    if (owner_id) {
      conditions.push(`m.owner_id = $${idx++}`);
      values.push(owner_id);
    }

    if (gn_division) {
      conditions.push(`$${idx++} = ANY(m.service_gn_divisions)`);
      values.push(gn_division);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

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
    `;

    const result = await query(sql, values);
    res.status(200).json(result.rows);
  } catch (err: any) {
    if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
      let filtered = [...devMachines];

      if (is_active !== undefined) {
        const activeBool = is_active === 'true';
        filtered = filtered.filter((m) => m.is_active === activeBool);
      } else {
        filtered = filtered.filter((m) => m.is_active === true);
      }

      if (machine_type) {
        filtered = filtered.filter((m) => m.machine_type === machine_type);
      }

      if (owner_id) {
        filtered = filtered.filter((m) => m.owner_id === owner_id);
      }

      if (gn_division) {
        filtered = filtered.filter((m) =>
          m.service_gn_divisions.includes(gn_division as string)
        );
      }

      res.status(200).json(filtered);
      return;
    }

    console.error('Error fetching machines:', err);
    res.status(500).json({
      error: 'server_error',
      message: 'Failed to fetch machines.',
    });
  }
}

export async function getMachineById(req: Request, res: Response): Promise<void> {
  const { id } = req.params;

  try {
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
      WHERE m.id = $1
      GROUP BY m.id, u.id
    `;

    const result = await query(sql, [id]);
    if (result.rows.length === 0) {
      res.status(404).json({
        error: 'machine_not_found',
        message: 'Machine listing not found.',
      });
      return;
    }

    const machine = result.rows[0];
    const slotsResult = await query(
      `SELECT * FROM availability_slots 
       WHERE machine_id = $1 AND slot_date >= CURRENT_DATE 
       ORDER BY slot_date ASC, start_time ASC`,
      [id]
    );
    machine.available_slots = slotsResult.rows;

    res.status(200).json(machine);
  } catch (err: any) {
    if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
      const match = devMachines.find((m) => m.id === id);
      if (!match) {
        res.status(404).json({
          error: 'machine_not_found',
          message: 'Machine listing not found.',
        });
        return;
      }
      res.status(200).json({ ...match, available_slots: [] });
      return;
    }

    console.error('Error fetching machine detail:', err);
    res.status(500).json({
      error: 'server_error',
      message: 'Failed to fetch machine detail.',
    });
  }
}

export async function updateMachine(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id } = req.params;

  try {
    const existingResult = await query<MachineRecord>(
      'SELECT * FROM machines WHERE id = $1',
      [id]
    );

    if (existingResult.rows.length === 0) {
      res.status(404).json({
        error: 'machine_not_found',
        message: 'Machine listing not found.',
      });
      return;
    }

    const machine = existingResult.rows[0];

    if (machine.owner_id !== req.user.id && req.user.role !== 'admin') {
      res.status(403).json({
        error: 'forbidden',
        message: 'You can only edit your own machine listings.',
      });
      return;
    }

    const parseResult = updateMachineSchema.safeParse(req.body);
    if (!parseResult.success) {
      res.status(400).json({
        error: 'validation_error',
        message: parseResult.error.issues[0]?.message || 'Invalid input data.',
        details: parseResult.error.issues,
      });
      return;
    }

    const data = parseResult.data;
    const effectiveType = data.machine_type || machine.machine_type;
    const effectiveDriveType =
      data.drive_type !== undefined ? data.drive_type : machine.drive_type;

    if (effectiveType === 'four_wheel_tractor' && !effectiveDriveType) {
      res.status(400).json({
        error: 'drive_type_required',
        message: 'Four-wheel tractors require a drive type (2WD or 4WD).',
      });
      return;
    }

    if (effectiveType !== 'four_wheel_tractor' && effectiveDriveType) {
      res.status(400).json({
        error: 'drive_type_not_allowed',
        message: 'Drive type is only allowed for four-wheel tractors.',
      });
      return;
    }

    const updateResult = await query<MachineRecord>(
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
        data.machine_type || null,
        data.brand || null,
        data.drive_type || null,
        data.model_name || null,
        data.rate_amount || null,
        data.rate_unit || null,
        data.photo_url || null,
        data.service_gn_divisions || null,
        data.is_active !== undefined ? data.is_active : null,
        id,
      ]
    );

    res.status(200).json(updateResult.rows[0]);
  } catch (err: any) {
    if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
      const idx = devMachines.findIndex((m) => m.id === id);
      if (idx !== -1) {
        devMachines[idx] = {
          ...devMachines[idx],
          ...req.body,
          updated_at: new Date(),
        };
        res.status(200).json(devMachines[idx]);
        return;
      }
    }

    console.error('Error updating machine:', err);
    res.status(500).json({
      error: 'server_error',
      message: 'Failed to update machine listing.',
    });
  }
}

export async function deleteMachine(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id } = req.params;

  try {
    const existing = await query<MachineRecord>(
      'SELECT * FROM machines WHERE id = $1',
      [id]
    );

    if (existing.rows.length === 0) {
      res.status(404).json({
        error: 'machine_not_found',
        message: 'Machine listing not found.',
      });
      return;
    }

    const machine = existing.rows[0];
    if (machine.owner_id !== req.user.id && req.user.role !== 'admin') {
      res.status(403).json({
        error: 'forbidden',
        message: 'You can only deactivate your own machine listings.',
      });
      return;
    }

    await query(
      'UPDATE machines SET is_active = false, updated_at = now() WHERE id = $1',
      [id]
    );

    res.status(200).json({
      message: 'Machine listing deactivated successfully.',
    });
  } catch (err: any) {
    if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
      const idx = devMachines.findIndex((m) => m.id === id);
      if (idx !== -1) {
        devMachines[idx].is_active = false;
        res.status(200).json({ message: 'Machine listing deactivated successfully.' });
        return;
      }
    }

    console.error('Error deleting machine:', err);
    res.status(500).json({
      error: 'server_error',
      message: 'Failed to deactivate machine listing.',
    });
  }
}
