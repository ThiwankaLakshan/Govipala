require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const usersRoutes = require('./src/routes/users');
const machinesRoutes = require('./src/routes/machines');
const availabilityRoutes = require('./src/routes/availability');
const bookingsRoutes = require('./src/routes/bookings');
const reviewsRoutes = require('./src/routes/reviews');
const cleanupJob = require('./src/jobs/releaseExpiredPendingSlots');

const app = express();
const port = process.env.PORT || 3000;

// Enable security headers
app.use(helmet());

// Enable CORS
app.use(cors());

// HTTP request logger
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Parse request bodies
app.use(express.json());

// Routes mapping
app.use('/api/v1/users', usersRoutes);
app.use('/api/v1/machines', machinesRoutes);
app.use('/api/v1', availabilityRoutes);
app.use('/api/v1/bookings', bookingsRoutes);
app.use('/api/v1/reviews', reviewsRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// 404 Route handler
app.use((req, res) => {
  res.status(404).json({
    error: 'not_found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Centralized error handler
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  
  res.status(500).json({
    error: 'server_error',
    message: process.env.NODE_ENV === 'production' 
      ? 'An unexpected error occurred' 
      : err.message
  });
});

// Only start the server if we are not running integration tests
if (process.env.NODE_ENV !== 'test') {
  // Start background database cleanup scheduler
  cleanupJob.startCleanupJob();

  app.listen(port, () => {
    console.log(`AgriMachine Backend running in ${process.env.NODE_ENV || 'development'} mode on port ${port}`);
    console.log(`API Base URL: http://localhost:${port}/api/v1`);
  });
}

module.exports = app;
