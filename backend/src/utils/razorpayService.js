import Razorpay from 'razorpay';
import crypto from 'crypto';

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

export const createOrder = async (amount, currency = 'INR', receipt) => {
  try {
    const options = {
      amount: amount * 100, // Amount in smallest currency unit (paise)
      currency,
      receipt,
      notes: {
        "key1": "value3",
        "key2": "value2"
      }
    };
    const order = await razorpay.orders.create(options);
    return order;
  } catch (error) {
    console.error('Razorpay Create Order Error:', error);
    throw error;
  }
};

export const verifyPaymentSignature = (orderId, paymentId, signature) => {
  const text = orderId + '|' + paymentId;
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(text.toString())
    .digest('hex');
  
  return expectedSignature === signature;
};
