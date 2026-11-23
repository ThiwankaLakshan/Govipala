import fs from 'fs';
import path from 'path';
import { pool } from './index';

export async function initDb(): Promise<void> {
  console.log('Connecting to PostgreSQL and applying schema...');
  const schemaPath = path.join(__dirname, 'schema.sql');
  const schemaSql = fs.readFileSync(schemaPath, 'utf8');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(schemaSql);
    await client.query('COMMIT');
    console.log('✅ Schema applied successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Failed to apply database schema:', error);
    throw error;
  } finally {
    client.release();
  }
}

if (require.main === module) {
  initDb()
    .then(() => {
      console.log('Database initialization complete.');
      process.exit(0);
    })
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
