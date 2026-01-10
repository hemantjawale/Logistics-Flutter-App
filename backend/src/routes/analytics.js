import express from 'express';
import { Shipment, Vehicle, Payment } from '../models.js';

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

    const [totalPayments, pendingAmount, overdueAmount] = await Promise.all([
      Payment.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]),
      Payment.aggregate([
        { $match: { status: 'Pending' } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Payment.aggregate([
        { $match: { status: 'Overdue' } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
    ]);

    const totalAmount = totalPayments[0]?.total || 0;
    const pending = pendingAmount[0]?.total || 0;
    const overdue = overdueAmount[0]?.total || 0;

    const onTimeDelivery = totalShipments
      ? delivered / totalShipments
      : 0;

    res.json({
      shipments: {
        total: totalShipments,
        delivered,
        delayed,
        inTransit,
        onTimeDelivery,
      },
      fleet: {
        total: totalVehicles,
        active: activeVehicles,
        critical: criticalVehicles,
      },
      payments: {
        totalAmount,
        pending,
        overdue,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to compute analytics' });
  }
});

export default router;
