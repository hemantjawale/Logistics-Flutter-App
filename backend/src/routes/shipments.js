import express from 'express';
import { Shipment } from '../models.js';

const router = express.Router();

// CREATE shipment
router.post('/', async (req, res) => {
  try {
    const shipment = await Shipment.create(req.body);
    res.status(201).json(shipment);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to create shipment', details: err.message });
  }
});

// READ all shipments (with optional status filter)
router.get('/', async (req, res) => {
  try {
    const { status } = req.query;
    const query = {};
    if (status) query.status = status;

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
