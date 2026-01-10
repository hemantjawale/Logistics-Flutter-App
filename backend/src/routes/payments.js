import express from 'express';
import { Payment } from '../models.js';

const router = express.Router();

// CREATE payment
router.post('/', async (req, res) => {
  try {
    const payment = await Payment.create(req.body);
    res.status(201).json(payment);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to create payment', details: err.message });
  }
});

// READ all payments
router.get('/', async (req, res) => {
  try {
    const { status } = req.query;
    const query = {};
    if (status) query.status = status;

    const payments = await Payment.find(query).sort({ createdAt: -1 });
    res.json(payments);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

// READ single payment
router.get('/:id', async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id);
    if (!payment) return res.status(404).json({ error: 'Payment not found' });
    res.json(payment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch payment' });
  }
});

// UPDATE payment
router.put('/:id', async (req, res) => {
  try {
    const payment = await Payment.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!payment) return res.status(404).json({ error: 'Payment not found' });
    res.json(payment);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to update payment', details: err.message });
  }
});

// DELETE payment
router.delete('/:id', async (req, res) => {
  try {
    const result = await Payment.findByIdAndDelete(req.params.id);
    if (!result) return res.status(404).json({ error: 'Payment not found' });
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete payment' });
  }
});

export default router;
