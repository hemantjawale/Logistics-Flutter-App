import express from 'express';
import { Shipment, User } from '../models.js';
import { sendOtp, verifyOtp } from '../utils/otpService.js';

const router = express.Router();

// REQUEST DELIVERY OTP
router.post('/:id/otp', async (req, res) => {
  try {
    const shipment = await Shipment.findById(req.params.id).populate('customerId');
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });
    
    const customer = shipment.customerId;
    if (!customer || !customer.phone) {
      // For demo purposes if customer has no phone, we might want to allow bypass or error out
      return res.status(400).json({ error: 'Customer phone number not found on shipment' });
    }

    await sendOtp(customer.phone);
    res.json({ message: 'OTP sent to customer', phone: customer.phone }); // Return phone for debug/UI hint
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// COMPLETE DELIVERY (VERIFY OTP)
router.post('/:id/complete', async (req, res) => {
  try {
    const { otp } = req.body;
    if (!otp) return res.status(400).json({ error: 'OTP is required' });

    const shipment = await Shipment.findById(req.params.id).populate('customerId');
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });

    const customer = shipment.customerId;
    if (!customer || !customer.phone) {
      return res.status(400).json({ error: 'Customer phone number not found' });
    }

    // In a real app, you might want a "Force Complete" for managers, but here we enforce OTP
    const isValid = verifyOtp(customer.phone, otp);
    if (!isValid) return res.status(400).json({ error: 'Invalid or expired OTP' });

    shipment.status = 'Delivered';
    shipment.progress = 1.0;
    await shipment.save();

    res.json({ message: 'Shipment delivered successfully', shipment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to complete delivery' });
  }
});

// CREATE shipment
router.post('/', async (req, res) => {
  try {
    const data = req.body;
    
    // Dynamic Price Calculation Logic (Simple Mock)
    // Price = (Weight * 10) + (Volume * 5) + Base Fee
    if (data.weight && !data.price) {
      const volume = (data.dimensions?.length || 0) * (data.dimensions?.width || 0) * (data.dimensions?.height || 0);
      data.price = (data.weight * 10) + (volume * 0.005) + 500; // Base fee 500
      data.price = Math.round(data.price * 100) / 100; // Round to 2 decimals
    }

    // Auto-Assign Driver Logic
    if (data.autoAssignDriver && !data.driverId) {
      // Find first available driver (Mock logic: just find any driver)
      const driver = await User.findOne({ role: 'driver' });
      if (driver) {
        data.driverId = driver._id;
        data.driverName = driver.name;
        data.status = 'Pending'; // Driver needs to accept? For now, just assign.
      }
    } else if (data.driverId) {
       // Manual assignment
       const driver = await User.findById(data.driverId);
       if (driver) {
         data.driverName = driver.name;
       }
    }
    
    // Handle coordinates if provided in simplified format
    if (data.destinationLat && data.destinationLng) {
        data.dropoffLocation = {
            type: 'Point',
            coordinates: [data.destinationLng, data.destinationLat],
            address: data.destination
        };
    }

    const shipment = await Shipment.create(data);
    res.status(201).json(shipment);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to create shipment', details: err.message });
  }
});

// READ all shipments (with optional status filter)
router.get('/', async (req, res) => {
  try {
    const { status, driverId, customerId } = req.query;
    const query = {};
    if (status) query.status = status;
    if (driverId) query.driverId = driverId;
    if (customerId) query.customerId = customerId;

    const shipments = await Shipment.find(query).sort({ createdAt: -1 });
    res.json(shipments);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch shipments' });
  }
});

// READ single shipment
router.get('/:id', async (req, res) => {
  try {
    const shipment = await Shipment.findById(req.params.id);
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });
    res.json(shipment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch shipment' });
  }
});

// UPDATE shipment
router.put('/:id', async (req, res) => {
  try {
    const shipment = await Shipment.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });
    res.json(shipment);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to update shipment', details: err.message });
  }
});

// DELETE shipment
router.delete('/:id', async (req, res) => {
  try {
    const result = await Shipment.findByIdAndDelete(req.params.id);
    if (!result) return res.status(404).json({ error: 'Shipment not found' });
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete shipment' });
  }
});

export default router;
