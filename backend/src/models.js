import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: {
      type: String,
      enum: ['driver', 'customer', 'manager'],
      required: true,
    },
    phone: { type: String },
    status: { type: String, enum: ['Active', 'Suspended'], default: 'Active' },
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
    weight: { type: Number },
    dimensions: {
      length: { type: Number },
      width: { type: Number },
      height: { type: Number },
    },
    price: { type: Number },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    category: {
      type: String,
      enum: ['Agriculture', 'Textiles', 'Electronics', 'Pharmaceuticals', 'Automotive', 'FMCG', 'Construction', 'Other'],
      default: 'Other'
    },
    pickupLocation: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] },
      address: { type: String }
    },
    dropoffLocation: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] },
      address: { type: String }
    },
    notes: { type: String },
    incidents: [
      {
        type: { type: String, enum: ['Breakdown', 'Accident', 'Delay', 'Other'] },
        description: { type: String },
        timestamp: { type: Date, default: Date.now },
        reportedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      }
    ],
  },
  { timestamps: true }
);

shipmentSchema.index({ pickupLocation: '2dsphere' });
shipmentSchema.index({ dropoffLocation: '2dsphere' });

const vehicleSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true },
    type: { type: String, required: true },
    status: {
      type: String,
      enum: ['On Route', 'Idle', 'Maintenance', 'Offline'],
      default: 'Idle',
    },
    location: { type: String },
    currentCoordinates: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] },
    },
    utilization: { type: Number, min: 0, max: 1, default: 0 },
    health: {
      type: String,
      enum: ['Good', 'Attention', 'Critical'],
      default: 'Good',
    },
    mileage: { type: Number, default: 0 },
    lastServiceMileage: { type: Number, default: 0 },
    nextMaintenance: { type: Date },
    insuranceExpiry: { type: Date },
    pucExpiry: { type: Date },
    assignedDriver: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

vehicleSchema.index({ currentCoordinates: '2dsphere' });

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
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

const expenseSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Fuel', 'Maintenance', 'Poll', 'Salary', 'Rent', 'Other'], required: true },
    amount: { type: Number, required: true },
    date: { type: Date, default: Date.now },
    vehicleId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle' },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    receiptUrl: { type: String },
    notes: { type: String },
  },
  { timestamps: true }
);

export const User = mongoose.model('User', userSchema);
export const Shipment = mongoose.model('Shipment', shipmentSchema);
export const Vehicle = mongoose.model('Vehicle', vehicleSchema);
export const Payment = mongoose.model('Payment', paymentSchema);
export const Expense = mongoose.model('Expense', expenseSchema);

