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

// REPORT INCIDENT
router.post('/:id/incident', async (req, res) => {
  try {
    const { type, description, reportedBy } = req.body;
    if (!type || !description) return res.status(400).json({ error: 'Type and description are required' });

    const shipment = await Shipment.findById(req.params.id);
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });

    shipment.incidents.push({ type, description, reportedBy });
    
    // Automatically flag as Delayed if it's a breakdown or accident
    if (type === 'Breakdown' || type === 'Accident') {
      shipment.status = 'Delayed';
    }

    await shipment.save();
    res.json({ message: 'Incident reported successfully', shipment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to report incident' });
  }
});

// CREATE shipment
router.post('/', async (req, res) => {
  try {
    const data = req.body;
    
    // Validation
    if (!data.origin || !data.destination) {
      return res.status(400).json({ error: 'Origin and destination are required' });
    }
    
    // Dynamic Price Calculation Logic (Enhanced)
    // Price = (Weight * 10) + (Volume * 0.005) + Base Fee + Priority Multiplier
    if (data.weight && !data.price) {
      const volume = (data.dimensions?.length || 0) * (data.dimensions?.width || 0) * (data.dimensions?.height || 0);
      let basePrice = (data.weight * 10) + (volume * 0.005) + 500; // Base fee 500
      
      // Apply priority multiplier
      const priorityMultiplier = {
        'Low': 0.9,
        'Normal': 1.0,
        'High': 1.25,
        'Critical': 1.5
      };
      basePrice *= priorityMultiplier[data.priority] || 1.0;
      
      data.price = Math.round(basePrice * 100) / 100; // Round to 2 decimals
    }

    // Auto-Assign Driver Logic (Enhanced)
    if (data.autoAssignDriver && !data.driverId) {
      // Find first available driver (Enhanced logic: find driver with no active shipments)
      const activeShipments = await Shipment.find({ 
        status: { $in: ['Pending', 'In Transit'] }
      }).distinct('driverId');
      
      const driver = await User.findOne({ 
        role: 'driver', 
        _id: { $nin: activeShipments }
      });
      
      if (driver) {
        data.driverId = driver._id;
        data.driverName = driver.name;
        data.status = 'Pending';
      } else {
        // If no available driver, fallback to any driver
        const fallbackDriver = await User.findOne({ role: 'driver' });
        if (fallbackDriver) {
          data.driverId = fallbackDriver._id;
          data.driverName = fallbackDriver.name;
        }
      }
    } else if (data.driverId) {
       // Manual assignment
       const driver = await User.findById(data.driverId);
       if (driver) {
         data.driverName = driver.name;
       } else {
         return res.status(400).json({ error: 'Invalid driver ID' });
       }
    }
    
    // Validate customer if provided
    if (data.customerId) {
      const customer = await User.findById(data.customerId);
      if (!customer || customer.role !== 'customer') {
        return res.status(400).json({ error: 'Invalid customer ID' });
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

    // Set default ETA if not provided
    if (!data.eta) {
      const etaDays = {
        'Critical': 1,
        'High': 2,
        'Normal': 3,
        'Low': 5
      };
      const days = etaDays[data.priority] || 3;
      data.eta = new Date(Date.now() + (days * 24 * 60 * 60 * 1000));
    }

    const shipment = await Shipment.create(data);
    
    // Populate the created shipment with related data for response
    await shipment.populate('driverId', 'name email phone');
    await shipment.populate('customerId', 'name email phone');
    
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

    const shipments = await Shipment.find(query)
      .populate('driverId', 'name email phone')
      .populate('customerId', 'name email phone')
      .sort({ createdAt: -1 });
    res.json(shipments);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch shipments' });
  }
});

// READ single shipment
router.get('/:id', async (req, res) => {
  try {
    const shipment = await Shipment.findById(req.params.id)
      .populate('driverId', 'name email phone')
      .populate('customerId', 'name email phone');
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
