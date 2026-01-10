import express from 'express';
import { Payment, Shipment, User } from '../models.js';
import { createOrder, verifyPaymentSignature } from '../utils/razorpayService.js';

const router = express.Router();

// VERIFY Razorpay Payment and Create Shipment (End-to-End)
router.post('/verify-and-create-shipment', async (req, res) => {
  try {
    const { orderId, paymentId, signature, shipmentData } = req.body;
    
    // Verify payment signature
    const isValid = verifyPaymentSignature(orderId, paymentId, signature);
    if (!isValid) {
      return res.status(400).json({ error: 'Invalid payment signature' });
    }

    // Create payment record
    const payment = await Payment.create({
      invoiceNumber: `INV-${Date.now()}`,
      customerName: shipmentData.customerName || 'Customer',
      lane: `${shipmentData.origin} → ${shipmentData.destination}`,
      amount: shipmentData.price,
      currency: 'INR',
      status: 'Paid',
      method: 'Online',
      paidAt: new Date(),
      shipmentId: null, // Will be updated after shipment creation
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
    });

    // Create shipment
    const shipment = await Shipment.create({
      trackingNumber: shipmentData.trackingNumber,
      origin: shipmentData.origin,
      destination: shipmentData.destination,
      status: 'Pending',
      weight: shipmentData.weight,
      dimensions: shipmentData.dimensions,
      price: shipmentData.price,
      customerId: shipmentData.customerId,
      category: shipmentData.category,
      priority: shipmentData.priority,
      eta: shipmentData.eta || new Date(Date.now() + (3 * 24 * 60 * 60 * 1000)), // Default 3 days
      autoAssignDriver: shipmentData.autoAssignDriver,
      notes: shipmentData.notes,
    });

    // Auto-assign driver if requested
    if (shipmentData.autoAssignDriver && !shipmentData.driverId) {
      const activeShipments = await Shipment.find({ 
        status: { $in: ['Pending', 'In Transit'] }
      }).distinct('driverId');
      
      const driver = await User.findOne({ 
        role: 'driver', 
        _id: { $nin: activeShipments }
      });
      
      if (driver) {
        shipment.driverId = driver._id;
        shipment.driverName = driver.name;
        await shipment.save();
      }
    } else if (shipmentData.driverId) {
      const driver = await User.findById(shipmentData.driverId);
      if (driver) {
        shipment.driverId = driver._id;
        shipment.driverName = driver.name;
        await shipment.save();
      }
    }

    // Link payment to shipment
    payment.shipmentId = shipment._id;
    await payment.save();

    // Populate shipment data for response
    await shipment.populate('driverId', 'name email phone');
    await shipment.populate('customerId', 'name email phone');

    res.json({
      success: true,
      message: 'Payment verified and shipment created successfully',
      shipment,
      payment
    });

  } catch (err) {
    console.error('Payment verification and shipment creation error:', err);
    res.status(500).json({ 
      error: 'Failed to verify payment and create shipment', 
      details: err.message 
    });
  }
});

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
