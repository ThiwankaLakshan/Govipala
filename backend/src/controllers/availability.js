const db = require('../models/db');

/**
 * Owner creates one or more availability slots for a machine.
 */
async function createSlots(req, res) {
  const { id: machineId } = req.params;
  const { slots } = req.body;

  if (!slots || !Array.isArray(slots) || slots.length === 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'slots must be a non-empty array'
    });
  }

  try {
    // 1. Verify ownership of the machine
    const machineCheck = await db.query('SELECT * FROM machines WHERE id = $1', [machineId]);
    if (machineCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Machine not found'
      });
    }

    if (machineCheck.rows[0].owner_id !== req.user.id) {
      return res.status(403).json({
        error: 'forbidden',
        message: 'You do not own this machine'
      });
    }

    // 2. Validate format & insert slots
    const insertedIds = [];
    
    // Validate all slots first before starting insertion to prevent partial failure
    for (const slot of slots) {
      const { slot_date, start_time, end_time } = slot;
      if (!slot_date || !start_time || !end_time) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'Each slot must contain slot_date, start_time, and end_time'
        });
      }

      // Check format
      if (!/^\d{4}-\d{2}-\d{2}$/.test(slot_date)) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'slot_date must be in YYYY-MM-DD format'
        });
      }

      if (!/^\d{2}:\d{2}$/.test(start_time) || !/^\d{2}:\d{2}$/.test(end_time)) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'start_time and end_time must be in HH:MM format'
        });
      }

      if (start_time >= end_time) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'end_time must be later than start_time'
        });
      }
    }

    // Perform database writes
    for (const slot of slots) {
      const { slot_date, start_time, end_time } = slot;
      const queryText = `
        INSERT INTO availability_slots (machine_id, slot_date, start_time, end_time, status)
        VALUES ($1, $2, $3, $4, 'open')
        RETURNING id
      `;
      const result = await db.query(queryText, [machineId, slot_date, start_time, end_time]);
      insertedIds.push(result.rows[0].id);
    }

    return res.status(201).json({ created: insertedIds.length, ids: insertedIds });
  } catch (error) {
    console.error('Error creating availability slots:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while creating availability slots'
    });
  }
}

/**
 * Fetch availability slots for a machine in a date range.
 */
async function getSlots(req, res) {
  const { id: machineId } = req.params;
  const { from, to } = req.query;

  if (!from || !to) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'from and to query parameters (date) are required'
    });
  }

  try {
    const queryText = `
      SELECT * FROM availability_slots
      WHERE machine_id = $1 AND slot_date >= $2 AND slot_date <= $3
      ORDER BY slot_date ASC, start_time ASC
    `;
    const result = await db.query(queryText, [machineId, from, to]);

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching availability slots:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching availability slots'
    });
  }
}

/**
 * Remove an availability slot (open status only).
 */
async function deleteSlot(req, res) {
  const { slotId } = req.params;

  try {
    // 1. Fetch slot & machine owner
    const slotCheck = await db.query(`
      SELECT s.*, m.owner_id
      FROM availability_slots s
      JOIN machines m ON s.machine_id = m.id
      WHERE s.id = $1
    `, [slotId]);

    if (slotCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Availability slot not found'
      });
    }

    const slot = slotCheck.rows[0];

    // 2. Verify ownership
    if (slot.owner_id !== req.user.id) {
      return res.status(403).json({
        error: 'forbidden',
        message: 'You do not own the machine for this slot'
      });
    }

    // 3. Status checks
    if (slot.status !== 'open') {
      return res.status(400).json({
        error: 'invalid_action',
        message: `Cannot delete slot in '${slot.status}' state. Only 'open' slots can be removed.`
      });
    }

    // 4. Delete slot
    await db.query('DELETE FROM availability_slots WHERE id = $1', [slotId]);

    return res.status(200).json({
      message: 'Availability slot successfully removed'
    });
  } catch (error) {
    console.error('Error deleting availability slot:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while deleting availability slot'
    });
  }
}

module.exports = {
  createSlots,
  getSlots,
  deleteSlot
};
