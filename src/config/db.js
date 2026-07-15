const { Pool } = require('pg');
const logger = require('../utils/logger');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.connect()
  .then(() => logger.info('Connected to PostgreSQL', { host: process.env.DB_HOST, database: process.env.DB_NAME }))
  .catch(err => logger.error('PostgreSQL connection failed', { error: err.message, stack: err.stack }));

module.exports = pool;