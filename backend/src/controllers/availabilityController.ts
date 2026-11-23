import { Request, Response } from 'express';
import { query } from '../db';
import {
  createSlotsSchema,
  AvailabilitySlotRecord,
} from '../models/availability';
import { devSlots } from '../models/bookingStore';
import { devMachines } from './machineController';
import { MachineRecord } from '../models/machine';

function isDbConnectionError(err: any): boolean {
  return Boolean(
    err?.code === 'ECONNREFUSED' ||
    err?.message?.includes('connect ECONNREFUSED') ||
    (Array.isArray(err?.errors) && err.errors.some((e: any) => e?.code === 'ECONNREFUSED'))
  );
}

// POST /api/v1/machines/:id/availability
export async function createMachineAvailability(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { id: machineId } = req.params;
  const parseResult = createSlotsSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      error: 'validation_error',
      message: parseResult.error.issues[0]?.message || 'Invalid slot data.',
      details: parseResult.error.issues,
    });
    return;
  }

  const { slots } = parseResult.data;

  try {
    // 1. Verify machine exists and user is owner or admin
    const machineRes = await query<MachineRecord>('SELECT * FROM machines WHERE id = $1', [machineId]);
    if (machineRes.rows.length === 0) {
      res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
      return;
    }

    const machine = machineRes.rows[0];
    if (machine.owner_id !== req.user.id && req.user.role !== 'admin') {
      res.status(403).json({ error: 'forbidden', message: 'You can only add availability for your own machines.' });
      return;
    }

    // 2. Insert slots
    const createdSlots: AvailabilitySlotRecord[] = [];
    for (const slot of slots) {
      const insertRes = await query<AvailabilitySlotRecord>(
        `INSERT INTO availability_slots (machine_id, slot_date, start_time, end_time, status)
         VALUES ($1, $2, $3, $4, 'open')
         RETURNING *`,
        [machineId, slot.slot_date, slot.start_time, slot.end_time]
      );
      createdSlots.push(insertRes.rows[0]);
    }

    res.status(201).json({
      created: createdSlots.length,
      slots: createdSlots,
    });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      // Check in-memory dev machine
      const devMachine = devMachines.find((m) => m.id === machineId);
      if (!devMachine) {
        res.status(404).json({ error: 'machine_not_found', message: 'Machine not found.' });
        return;
      }

      if (devMachine.owner_id !== req.user.id && req.user.role !== 'admin') {
        res.status(403).json({ error: 'forbidden', message: 'You can only add availability for your own machines.' });
        return;
      }

      const createdSlots: AvailabilitySlotRecord[] = [];
      for (const slot of slots) {
        const newSlot: AvailabilitySlotRecord = {
          id: `dev-slot-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
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

      res.status(201).json({
        created: createdSlots.length,
        slots: createdSlots,
      });
      return;
    }

    console.error('Error creating availability slots:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create availability slots.' });
  }
}

// GET /api/v1/machines/:id/availability?from=&to=
export async function getMachineAvailability(req: Request, res: Response): Promise<void> {
  const { id: machineId } = req.params;
  const { from, to } = req.query;

  try {
    const conditions: string[] = ['machine_id = $1'];
    const values: any[] = [machineId];
    let idx = 2;

    if (from) {
      conditions.push(`slot_date >= $${idx++}`);
      values.push(from);
    } else {
      // By default show today onwards
      conditions.push(`slot_date >= CURRENT_DATE`);
    }

    if (to) {
      conditions.push(`slot_date <= $${idx++}`);
      values.push(to);
    }

    const sql = `
      SELECT * FROM availability_slots
      WHERE ${conditions.join(' AND ')}
      ORDER BY slot_date ASC, start_time ASC
    `;

    const result = await query<AvailabilitySlotRecord>(sql, values);
    res.status(200).json(result.rows);
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      let filtered = devSlots.filter((s) => s.machine_id === machineId);
      const todayStr = new Date().toISOString().split('T')[0];

      if (from) {
        filtered = filtered.filter((s) => s.slot_date >= (from as string));
      } else {
        filtered = filtered.filter((s) => s.slot_date >= todayStr);
      }

      if (to) {
        filtered = filtered.filter((s) => s.slot_date <= (to as string));
      }

      filtered.sort((a, b) => {
        if (a.slot_date !== b.slot_date) return a.slot_date.localeCompare(b.slot_date);
        return a.start_time.localeCompare(b.start_time);
      });

      res.status(200).json(filtered);
      return;
    }

    console.error('Error fetching availability:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch availability slots.' });
  }
}

// DELETE /api/v1/availability/:slotId
export async function deleteAvailabilitySlot(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'unauthorized', message: 'Authentication required.' });
    return;
  }

  const { slotId } = req.params;

  try {
    const slotRes = await query<AvailabilitySlotRecord & { owner_id: string }>(
      `SELECT s.*, m.owner_id 
       FROM availability_slots s
       JOIN machines m ON s.machine_id = m.id
       WHERE s.id = $1`,
      [slotId]
    );

    if (slotRes.rows.length === 0) {
      res.status(404).json({ error: 'slot_not_found', message: 'Availability slot not found.' });
      return;
    }

    const slot = slotRes.rows[0];
    if (slot.owner_id !== req.user.id && req.user.role !== 'admin') {
      res.status(403).json({ error: 'forbidden', message: 'You can only delete slots for your own machines.' });
      return;
    }

    // FR-3.3: Prevent deletion of pending or booked slots
    if (slot.status !== 'open') {
      res.status(400).json({
        error: 'cannot_delete_active_slot',
        message: 'Pending or booked slots cannot be deleted. Please respond to or cancel the booking first.',
      });
      return;
    }

    await query('DELETE FROM availability_slots WHERE id = $1', [slotId]);
    res.status(200).json({ message: 'Slot deleted successfully.' });
  } catch (err: any) {
    if (isDbConnectionError(err)) {
      const idx = devSlots.findIndex((s) => s.id === slotId);
      if (idx === -1) {
        res.status(404).json({ error: 'slot_not_found', message: 'Availability slot not found.' });
        return;
      }

      const slot = devSlots[idx];
      const machine = devMachines.find((m) => m.id === slot.machine_id);

      if (machine && machine.owner_id !== req.user.id && req.user.role !== 'admin') {
        res.status(403).json({ error: 'forbidden', message: 'You can only delete slots for your own machines.' });
        return;
      }

      if (slot.status !== 'open') {
        res.status(400).json({
          error: 'cannot_delete_active_slot',
          message: 'Pending or booked slots cannot be deleted.',
        });
        return;
      }

      devSlots.splice(idx, 1);
      res.status(200).json({ message: 'Slot deleted successfully.' });
      return;
    }

    console.error('Error deleting availability slot:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to delete availability slot.' });
  }
}
