const db = require('../models/db');

const ALLOWED_GN_DIVISIONS = [
  "Padaviya Town",
  "Aluth Halmillawa",
  "Ruwanpura",
  "1 Kanuwa",
  "A Yaya",
  "B Yaya",
  "C Yaya",
  "Maithreepura",
  "Budhdhangala",
  "Parakramapura",
  "Aliwanguwa",
  "Sripura"
];

const ALLOWED_MACHINE_TYPES = [
  "four_wheel_tractor",
  "four_wheel_tractor_with_trailer",
  "two_wheel_tractor",
  "two_wheel_tractor_with_trailer",
  "combine_harvester"
];

const ALLOWED_RATE_UNITS = ["hour", "day", "acre"];

/**
 * Owner creates a machine listing.
 */
async function createMachine(req, res) {
  // 1. Role-based Authentication check
  if (!req.user || (req.user.role !== 'owner' && req.user.role !== 'both')) {
    return res.status(403).json({
      error: 'forbidden',
      message: 'Only registered users with roles "owner" or "both" can list machines'
    });
  }

  const { machine_type, model_name, paddy_type, rate_amount, rate_unit, photo_url, service_gn_divisions } = req.body;

  // 2. Standard field validations
  if (!machine_type || rate_amount === undefined || !rate_unit || !service_gn_divisions) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'machine_type, rate_amount, rate_unit, and service_gn_divisions are required'
    });
  }

  if (!ALLOWED_MACHINE_TYPES.includes(machine_type)) {
    return res.status(400).json({
      error: 'validation_failed',
      message: `machine_type must be one of: ${ALLOWED_MACHINE_TYPES.join(', ')}`
    });
  }

  if (!ALLOWED_RATE_UNITS.includes(rate_unit)) {
    return res.status(400).json({
      error: 'validation_failed',
      message: `rate_unit must be one of: ${ALLOWED_RATE_UNITS.join(', ')}`
    });
  }

  const parsedRate = parseFloat(rate_amount);
  if (isNaN(parsedRate) || parsedRate <= 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'rate_amount must be a positive number'
    });
  }

  // 3. GN division list validation
  if (!Array.isArray(service_gn_divisions) || service_gn_divisions.length === 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'service_gn_divisions must be a non-empty array of GN divisions'
    });
  }

  const invalidDivisions = service_gn_divisions.filter(div => !ALLOWED_GN_DIVISIONS.includes(div));
  if (invalidDivisions.length > 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: `The following GN divisions are invalid: ${invalidDivisions.join(', ')}. Must be within Padaviya DS division.`
    });
  }

  // 4. Tractor Paddy type validation
  let finalPaddyType = null;
  const isTractor = ['four_wheel_tractor', 'two_wheel_tractor'].includes(machine_type);
  if (isTractor) {
    if (!paddy_type) {
      return res.status(400).json({
        error: 'validation_failed',
        message: 'paddy_type (mud or dry) is required for field preparation tractors'
      });
    }
    if (!['mud', 'dry'].includes(paddy_type)) {
      return res.status(400).json({
        error: 'validation_failed',
        message: 'paddy_type must be either "mud" or "dry" for tractors'
      });
    }
    finalPaddyType = paddy_type;
  }

  try {
    const queryText = `
      INSERT INTO machines (owner_id, machine_type, model_name, paddy_type, rate_amount, rate_unit, photo_url, service_gn_divisions)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, owner_id, machine_type, model_name, paddy_type, rate_amount, rate_unit, photo_url, service_gn_divisions, is_active, created_at
    `;
    const params = [req.user.id, machine_type, model_name || null, finalPaddyType, parsedRate, rate_unit, photo_url || null, service_gn_divisions];
    const result = await db.query(queryText, params);

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating machine listing:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error during machine listing creation'
    });
  }
}

/**
 * Farmer searches/browses machines.
 * Query params: machine_type, gn_division, date (date is stubbed for now until slot logic)
 */
async function getMachines(req, res) {
  const { machine_type, gn_division } = req.query;
  const conditions = ['is_active = true'];
  const params = [];
  let paramCount = 1;

  if (machine_type) {
    if (!ALLOWED_MACHINE_TYPES.includes(machine_type)) {
      return res.status(400).json({
        error: 'validation_failed',
        message: 'Invalid machine_type'
      });
    }
    conditions.push(`machine_type = $${paramCount++}`);
    params.push(machine_type);
  }

  if (gn_division) {
    if (!ALLOWED_GN_DIVISIONS.includes(gn_division)) {
      return res.status(400).json({
        error: 'validation_failed',
        message: 'Invalid gn_division'
      });
    }
    conditions.push(`$${paramCount++} = ANY(service_gn_divisions)`);
    params.push(gn_division);
  }

  const queryText = `
    SELECT m.*, u.full_name as owner_name, COALESCE(AVG(r.rating), 0)::numeric(3,2) as average_rating
    FROM machines m
    JOIN users u ON m.owner_id = u.id
    LEFT JOIN bookings b ON b.farmer_id = u.id -- dummy joins for rating logic structure
    LEFT JOIN reviews r ON r.reviewee_id = u.id
    WHERE ${conditions.join(' AND ')}
    GROUP BY m.id, u.full_name
  `;

  try {
    const result = await db.query(queryText, params);
    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching machines:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching machines list'
    });
  }
}

/**
 * Full machine details.
 */
async function getMachineById(req, res) {
  const { id } = req.params;

  try {
    const queryText = `
      SELECT m.*, u.full_name as owner_name, u.phone_number as owner_phone, COALESCE(AVG(r.rating), 0)::numeric(3,2) as average_rating
      FROM machines m
      JOIN users u ON m.owner_id = u.id
      LEFT JOIN reviews r ON r.reviewee_id = u.id
      WHERE m.id = $1 AND m.is_active = true
      GROUP BY m.id, u.full_name, u.phone_number
    `;
    const result = await db.query(queryText, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Machine listing not found or inactive'
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching machine detail:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while fetching machine details'
    });
  }
}

/**
 * Owner updates listing.
 */
async function updateMachine(req, res) {
  const { id } = req.params;

  try {
    // 1. Fetch machine to verify ownership
    const checkResult = await db.query('SELECT * FROM machines WHERE id = $1', [id]);
    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Machine listing not found'
      });
    }

    const machine = checkResult.rows[0];

    // 2. Ownership verification
    if (machine.owner_id !== req.user.id) {
      return res.status(403).json({
        error: 'forbidden',
        message: 'You do not have permission to modify this listing'
      });
    }

    const { model_name, paddy_type, rate_amount, rate_unit, photo_url, service_gn_divisions, is_active } = req.body;
    const updates = [];
    const params = [];
    let paramCount = 1;

    // Validate and add fields if provided
    if (model_name !== undefined) {
      updates.push(`model_name = $${paramCount++}`);
      params.push(model_name);
    }

    if (rate_amount !== undefined) {
      const parsedRate = parseFloat(rate_amount);
      if (isNaN(parsedRate) || parsedRate <= 0) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'rate_amount must be a positive number'
        });
      }
      updates.push(`rate_amount = $${paramCount++}`);
      params.push(parsedRate);
    }

    if (rate_unit !== undefined) {
      if (!ALLOWED_RATE_UNITS.includes(rate_unit)) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'Invalid rate_unit'
        });
      }
      updates.push(`rate_unit = $${paramCount++}`);
      params.push(rate_unit);
    }

    // Handle conditional paddy type update
    if (paddy_type !== undefined) {
      const currentType = req.body.machine_type || machine.machine_type;
      const isTractor = ['four_wheel_tractor', 'two_wheel_tractor'].includes(currentType);
      
      if (isTractor) {
        if (!paddy_type || !['mud', 'dry'].includes(paddy_type)) {
          return res.status(400).json({
            error: 'validation_failed',
            message: 'paddy_type must be either "mud" or "dry" for tractors'
          });
        }
        updates.push(`paddy_type = $${paramCount++}`);
        params.push(paddy_type);
      } else {
        updates.push(`paddy_type = $${paramCount++}`);
        params.push(null);
      }
    }

    if (photo_url !== undefined) {
      updates.push(`photo_url = $${paramCount++}`);
      params.push(photo_url);
    }

    if (service_gn_divisions !== undefined) {
      if (!Array.isArray(service_gn_divisions) || service_gn_divisions.length === 0) {
        return res.status(400).json({
          error: 'validation_failed',
          message: 'service_gn_divisions must be a non-empty array'
        });
      }
      const invalidDivisions = service_gn_divisions.filter(div => !ALLOWED_GN_DIVISIONS.includes(div));
      if (invalidDivisions.length > 0) {
        return res.status(400).json({
          error: 'validation_failed',
          message: `The following GN divisions are invalid: ${invalidDivisions.join(', ')}`
        });
      }
      updates.push(`service_gn_divisions = $${paramCount++}`);
      params.push(service_gn_divisions);
    }

    if (is_active !== undefined) {
      updates.push(`is_active = $${paramCount++}`);
      params.push(is_active);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        error: 'validation_failed',
        message: 'No update parameters provided'
      });
    }

    params.push(id);
    const queryText = `
      UPDATE machines
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, owner_id, machine_type, model_name, paddy_type, rate_amount, rate_unit, photo_url, service_gn_divisions, is_active, updated_at
    `;

    const result = await db.query(queryText, params);
    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating machine listing:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error while updating machine'
    });
  }
}

/**
 * Soft delete (deactivate) machine listing.
 */
async function deleteMachine(req, res) {
  const { id } = req.params;

  try {
    // 1. Fetch machine to verify ownership
    const checkResult = await db.query('SELECT * FROM machines WHERE id = $1', [id]);
    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: 'not_found',
        message: 'Machine listing not found'
      });
    }

    const machine = checkResult.rows[0];

    // 2. Ownership verification
    if (machine.owner_id !== req.user.id) {
      return res.status(403).json({
        error: 'forbidden',
        message: 'You do not have permission to delete this listing'
      });
    }

    // 3. Soft-delete
    await db.query('UPDATE machines SET is_active = false WHERE id = $1', [id]);

    return res.status(200).json({
      message: 'Machine listing successfully deactivated'
    });
  } catch (error) {
    console.error('Error deactivating machine listing:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error during machine deactivation'
    });
  }
}

module.exports = {
  createMachine,
  getMachines,
  getMachineById,
  updateMachine,
  deleteMachine
};
