import express from 'express';
import { getAIInsights, predictShipmentDelay } from '../services/ai_service.js';
import { Shipment, Vehicle, Payment, Expense } from '../models.js';

const router = express.Router();

router.get('/insights', async (req, res) => {
  try {
    // Collect data for AI context
    const [shipmentsCount, fleetSummary, payments, expenses] = await Promise.all([
      Shipment.countDocuments({ status: 'Delayed' }),
      Vehicle.find({ health: 'Critical' }).select('code health location'),
      Payment.find({ status: 'Overdue' }).select('amount customerName'),
      Expense.aggregate([{ $group: { _id: '$type', total: { $sum: '$amount' } } }])
    ]);

    const context = {
      delayedShipments: shipmentsCount,
      criticalVehicles: fleetSummary,
      overduePayments: payments,
      expenseBreakdown: expenses
    };

    const aiResponse = await getAIInsights(context);
    res.json(aiResponse);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to generate AI insights' });
  }
});

router.get('/predict-delay/:shipmentId', async (req, res) => {
  try {
    const shipment = await Shipment.findById(req.params.shipmentId);
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });

    const prediction = await predictShipmentDelay(shipment);
    res.json(prediction);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'AI Prediction failed' });
  }
});

export default router;
