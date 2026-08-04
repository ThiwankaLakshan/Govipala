const db = require('../models/db');

/**
 * Register a new user in PostgreSQL database.
 * Associated Firebase UID and phone number are resolved from Firebase token verification.
 */
async function register(req, res) {
  const { full_name, role, gn_division, preferred_lang } = req.body;

  // Validate request parameters
  if (!full_name || !role || !gn_division) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'full_name, role, and gn_division are required fields'
    });
  }

  if (!['owner', 'farmer', 'both'].includes(role)) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'role must be one of: owner, farmer, both'
    });
  }

  // If user is already registered (req.user exists from token search)
  if (req.user) {
    return res.status(409).json({
      error: 'already_registered',
      message: 'A user is already registered with this phone number'
    });
  }

  // Firebase information must be available from verifyFirebaseToken middleware
  if (!req.firebaseUser) {
    return res.status(400).json({
      error: 'registration_failed',
      message: 'No un-registered auth session found. Authenticate via Firebase first.'
    });
  }

  const { uid: firebase_uid, phone_number } = req.firebaseUser;
  const lang = preferred_lang || 'en'; // default to English

  try {
    // Insert user into Postgres
    const queryText = `
      INSERT INTO users (phone_number, firebase_uid, full_name, role, gn_division, preferred_lang)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, phone_number, firebase_uid, full_name, role, gn_division, preferred_lang, created_at
    `;
    const params = [phone_number, firebase_uid, full_name, role, gn_division, lang];
    const result = await db.query(queryText, params);
    
    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error registering user:', error);
    
    // Check for unique constraint violation (phone_number or firebase_uid)
    if (error.code === '23505') {
      return res.status(409).json({
        error: 'already_registered',
        message: 'A user with this phone number or Firebase UID is already registered'
      });
    }
    
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error during user registration'
    });
  }
}

/**
 * Return current authenticated user profile
 */
async function getMe(req, res) {
  if (!req.user) {
    // Verified Firebase token but no database record yet
    return res.status(404).json({
      error: 'user_not_registered',
      message: 'Authentication token is valid, but the user profile is not registered yet.',
      firebaseUser: req.firebaseUser
    });
  }
  
  return res.status(200).json(req.user);
}

/**
 * Update authenticated user profile fields
 */
async function updateMe(req, res) {
  if (!req.user) {
    return res.status(404).json({
      error: 'user_not_registered',
      message: 'User profile is not registered yet.'
    });
  }

  const { full_name, gn_division, preferred_lang } = req.body;
  const updates = [];
  const params = [];
  let paramCount = 1;

  if (full_name !== undefined) {
    updates.push(`full_name = $${paramCount++}`);
    params.push(full_name);
  }
  if (gn_division !== undefined) {
    updates.push(`gn_division = $${paramCount++}`);
    params.push(gn_division);
  }
  if (preferred_lang !== undefined) {
    updates.push(`preferred_lang = $${paramCount++}`);
    params.push(preferred_lang);
  }

  if (updates.length === 0) {
    return res.status(400).json({
      error: 'validation_failed',
      message: 'At least one field (full_name, gn_division, preferred_lang) must be provided to update'
    });
  }

  params.push(req.user.id);
  const queryText = `
    UPDATE users
    SET ${updates.join(', ')}
    WHERE id = $${paramCount}
    RETURNING id, phone_number, firebase_uid, full_name, role, gn_division, preferred_lang, created_at, updated_at
  `;

  try {
    const result = await db.query(queryText, params);
    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user profile:', error);
    return res.status(500).json({
      error: 'server_error',
      message: 'Internal server error during user profile update'
    });
  }
}

module.exports = {
  register,
  getMe,
  updateMe
};
