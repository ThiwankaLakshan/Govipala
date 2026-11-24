import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import userRoutes from './routes/userRoutes';
import locationRoutes from './routes/locationRoutes';
import machineRoutes from './routes/machineRoutes';
import availabilityRoutes from './routes/availabilityRoutes';
import bookingRoutes from './routes/bookingRoutes';
import adminRoutes from './routes/adminRoutes';
import notificationRoutes from './routes/notificationRoutes';
import authRoutes from './routes/authRoutes';

export const app = express();

app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// Health check
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'govipala-api', timestamp: new Date().toISOString() });
});

// REST API v1 routes
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/locations', locationRoutes);
app.use('/api/v1/machines', machineRoutes);
app.use('/api/v1/availability', availabilityRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/auth', authRoutes);

// Fallback 404 handler
app.use((_req, res) => {
  res.status(404).json({
    error: 'not_found',
    message: 'The requested API endpoint was not found.',
  });
});

// Global error handler
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled API error:', err);
  res.status(500).json({
    error: 'internal_server_error',
    message: 'An unexpected error occurred.',
  });
});
