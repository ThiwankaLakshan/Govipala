const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
  getClient: async () => {
    const client = await pool.connect();
    const query = client.query.bind(client);
    const release = client.release.bind(client);
    
    // Set a self-timeout of 5 seconds for safety
    const timeout = setTimeout(() => {
      console.error('A database client has been active for more than 5 seconds!');
      console.error('It might lead to a connection pool leak.');
    }, 5000);

    client.release = () => {
      clearTimeout(timeout);
      release();
    };

    return client;
  }
};
