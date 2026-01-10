import express from 'express';
import { User } from '../models.js';
import { sendOtp, verifyOtp } from '../utils/otpService.js';

const router = express.Router();

// REQUEST OTP (For Registration or Forgot Password)
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'Phone number required' });
    
    await sendOtp(phone);
    res.json({ message: 'OTP sent successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// REGISTER (Create User with OTP Verification)
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, phone, otp } = req.body;
    // Basic validation
    if (!name || !email || !password || !role) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (phone && otp) {
      const isValid = verifyOtp(phone, otp);
      if (!isValid) return res.status(400).json({ error: 'Invalid or expired OTP' });
    } else if (phone) {
        // If phone provided but no OTP, maybe enforce it? 
        // For now, let's assume if phone is there, OTP is required.
        return res.status(400).json({ error: 'OTP required for phone registration' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const user = await User.create({ name, email, password, role, phone });
    res.status(201).json({ message: 'User registered successfully', user });
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to register user', details: err.message });
  }
});

// FORGOT PASSWORD - RESET
router.post('/reset-password', async (req, res) => {
  try {
    const { phone, otp, newPassword } = req.body;
    if (!phone || !otp || !newPassword) {
      return res.status(400).json({ error: 'Phone, OTP and New Password required' });
    }

    const isValid = verifyOtp(phone, otp);
    if (!isValid) return res.status(400).json({ error: 'Invalid or expired OTP' });

    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.password = newPassword; // In production, hash this!
    await user.save();

    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to reset password' });
  }
});

// LOGIN (Simple auth)
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user || user.password !== password) { // In production, compare hashed passwords!
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.json({ message: 'Login successful', user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// GET DRIVERS (New Endpoint)
router.get('/drivers', async (req, res) => {
  try {
    const drivers = await User.find({ role: 'driver' }).select('name email phone status');
    res.json(drivers);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch drivers' });
  }
});

// GET CUSTOMERS (New Endpoint)
router.get('/customers', async (req, res) => {
  try {
    const customers = await User.find({ role: 'customer' }).select('name email phone status');
    res.json(customers);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch customers' });
  }
});

// READ all users
router.get('/', async (req, res) => {
  try {
    const users = await User.find({}).select('-password'); // Exclude password
    res.json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// READ single user
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// UPDATE user
router.put('/:id', async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    }).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Failed to update user', details: err.message });
  }
});

// DELETE user
router.delete('/:id', async (req, res) => {
  try {
    const result = await User.findByIdAndDelete(req.params.id);
    if (!result) return res.status(404).json({ error: 'User not found' });
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

export default router;
