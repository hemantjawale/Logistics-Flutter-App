import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true }, // In production, hash this!
    role: {
      type: String,
      enum: ['driver', 'customer', 'manager'],
      required: true,
    },
    phone: { type: String },
  },
  { timestamps: true }
);

const shipmentSchema = new mongoose.Schema(
  {
    trackingNumber: { type: String, required: true, unique: true },
    origin: { type: String, required: true },
    destination: { type: String, required: true },
    status: {
      type: String,
      enum: ['Pending', 'In Transit', 'Delivered', 'Delayed', 'Cancelled'],
      default: 'Pending',
    },
    eta: { type: Date },
    route: { type: String },
    driverName: { type: String },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    vehicleId: { type: String },
    priority: { type: String, enum: ['Low', 'Normal', 'High', 'Critical'], default: 'Normal' },
    progress: { type: Number, min: 0, max: 1, default: 0 },
    // New fields
    weight: { type: Number }, // in kg
    dimensions: {
      length: { type: Number },
      width: { type: Number },
      height: { type: Number },
    },
    price: { type: Number },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    pickupLocation: {
      lat: { type: Number },
      lng: { type: Number },
    },
    dropoffLocation: {
      lat: { type: Number },
      lng: { type: Number },
    },
  },
  { timestamps: true }
);

const vehicleSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true },
    type: { type: String, required: true }, // Reefer, Container, etc.
    status: {
      type: String,
      enum: ['On Route', 'Idle', 'Maintenance', 'Offline'],
      default: 'Idle',
    },
    location: { type: String },
    utilization: { type: Number, min: 0, max: 1, default: 0 },
    health: {
      type: String,
      enum: ['Good', 'Attention', 'Critical'],
      default: 'Good',
    },
    nextMaintenance: { type: Date },
  },
  { timestamps: true }
);

const paymentSchema = new mongoose.Schema(
  {
    invoiceNumber: { type: String, required: true, unique: true },
    customerName: { type: String, required: true },
    lane: { type: String },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    status: { type: String, enum: ['Paid', 'Pending', 'Overdue'], default: 'Pending' },
    method: { type: String, enum: ['UPI', 'NEFT', 'Card', 'Cash'], default: 'UPI' },
    dueDate: { type: Date },
    paidAt: { type: Date },
    shipmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shipment' },
  },
  { timestamps: true }
);

export const User = mongoose.model('User', userSchema);
export const Shipment = mongoose.model('Shipment', shipmentSchema);
export const Vehicle = mongoose.model('Vehicle', vehicleSchema);
export const Payment = mongoose.model('Payment', paymentSchema);
