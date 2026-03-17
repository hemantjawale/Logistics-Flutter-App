import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';

// Configure dotenv to load from parent directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '../.env') });

// Debug environment loading
console.log('Current working directory:', process.cwd());
console.log('Script directory:', __dirname);
console.log('Env file path:', path.resolve(__dirname, '../.env'));
console.log('Environment variables after dotenv config:');
console.log('RAZORPAY_KEY_ID:', process.env.RAZORPAY_KEY_ID);
console.log('RAZORPAY_KEY_SECRET:', process.env.RAZORPAY_KEY_SECRET);
console.log('MONGO_URI:', process.env.MONGO_URI);

import shipmentsRouter from './routes/shipments.js';
import fleetRouter from './routes/fleet.js';
import paymentsRouter from './routes/payments.js';
import analyticsRouter from './routes/analytics.js';
import usersRouter from './routes/users.js';
import aiRouter from './routes/ai.js';

const app = express();

app.use(cors());
app.use(express.json());

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Logistics backend running' });
});

// API routes
app.use('/api/shipments', shipmentsRouter);
app.use('/api/fleet', fleetRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/users', usersRouter);
app.use('/api/ai', aiRouter);

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error('Missing MONGO_URI in environment');
  process.exit(1);
}

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`Server listening on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection error', err);
    process.exit(1);
  });
