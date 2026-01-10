import express from 'express';
import { Shipment, User } from '../models.js';

const router = express.Router();

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
    if (data.autoAssignDriver) {
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
