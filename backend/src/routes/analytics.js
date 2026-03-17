import express from 'express';
import { Shipment, Vehicle, Payment, Expense } from '../models.js';

const router = express.Router();

// Summary dashboard KPIs
router.get('/summary', async (req, res) => {
  try {
    const [totalShipments, delivered, delayed, inTransit] = await Promise.all([
      Shipment.countDocuments({}),
      Shipment.countDocuments({ status: 'Delivered' }),
      Shipment.countDocuments({ status: 'Delayed' }),
      Shipment.countDocuments({ status: 'In Transit' }),
    ]);

    const [totalVehicles, activeVehicles, criticalVehicles] = await Promise.all([
      Vehicle.countDocuments({}),
      Vehicle.countDocuments({ status: 'On Route' }),
      Vehicle.countDocuments({ health: 'Critical' }),
    ]);

    // Financial Overview
    const [payments, expenses] = await Promise.all([
      Payment.aggregate([
        { $group: { _id: '$status', total: { $sum: '$amount' }, count: { $addToSet: '$_id' } } }
      ]),
      Expense.aggregate([
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ])
    ]);

    // Format payment split
    const paymentMetrics = { received: 0, pending: 0, overdue: 0 };
    payments.forEach(p => {
      if (p._id === 'Paid') paymentMetrics.received = p.total;
      if (p._id === 'Pending') paymentMetrics.pending = p.total;
      if (p._id === 'Overdue') paymentMetrics.overdue = p.total;
    });

    // Top Customers by Revenue
    const topCustomers = await Payment.aggregate([
      { $match: { status: 'Paid' } },
      { $group: { _id: '$customerName', totalRevenue: { $sum: '$amount' } } },
      { $sort: { totalRevenue: -1 } },
      { $limit: 5 }
    ]);

    const totalRevenue = Object.values(paymentMetrics).reduce((a, b) => a + b, 0);
    const totalExpense = expenses[0]?.total || 0;

    res.json({
      shipments: {
        total: totalShipments,
        delivered,
        delayed,
        inTransit,
        onTimeDelivery: totalShipments ? delivered / totalShipments : 0,
      },
      fleet: {
        total: totalVehicles,
        active: activeVehicles,
        critical: criticalVehicles,
      },
      payments: {
        ...paymentMetrics,
        totalRevenue,
      },
      expenses: {
        total: totalExpense,
      },
      topCustomers: topCustomers.map(c => ({ name: c._id, revenue: c.totalRevenue })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to compute analytics' });
  }
});

export default router;

