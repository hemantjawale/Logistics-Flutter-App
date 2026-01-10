import express from 'express';
import { Payment } from '../models.js';
import { createOrder, verifyPaymentSignature } from '../utils/razorpayService.js';

const router = express.Router();

// CREATE Razorpay Order
router.post('/create-order', async (req, res) => {
  try {
    const { amount, currency, receipt } = req.body;
    const order = await createOrder(amount, currency, receipt);
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create Razorpay order' });
  }
});

// VERIFY Razorpay Payment
router.post('/verify-payment', async (req, res) => {
  try {
    const { orderId, paymentId, signature, paymentData } = req.body;
    const isValid = verifyPaymentSignature(orderId, paymentId, signature);
    
    if (isValid) {
        // Create or update payment record
        if (paymentData) {
            await Payment.create({
                ...paymentData,
                status: 'Paid',
                method: 'Online',
                paidAt: new Date()
            });
        }
        res.json({ success: true });
    } else {
        res.status(400).json({ error: 'Invalid signature' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// CREATE payment (Manual)
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
