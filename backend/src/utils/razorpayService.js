import Razorpay from 'razorpay';
import crypto from 'crypto';

// Check if environment variables are loaded
console.log('Razorpay Key ID:', process.env.RAZORPAY_KEY_ID ? 'Set' : 'Not set');
console.log('Razorpay Key Secret:', process.env.RAZORPAY_KEY_SECRET ? 'Set' : 'Not set');

let razorpay = null;

try {
  if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
    console.log('Razorpay initialized successfully');
  } else {
    console.error('Razorpay credentials not found in environment variables');
  }
} catch (error) {
  console.error('Failed to initialize Razorpay:', error);
}

export const createOrder = async (amount, currency = 'INR', receipt) => {
  try {
    if (!razorpay) {
      throw new Error('Razorpay not initialized. Check environment variables.');
    }
    
    console.log('Creating Razorpay order with amount:', amount, 'currency:', currency, 'receipt:', receipt);
    
    const options = {
      amount: amount * 100, // Amount in smallest currency unit (paise)
      currency,
      receipt,
      notes: {
        "key1": "value3",
        "key2": "value2"
      }
    };
    
    console.log('Razorpay options:', JSON.stringify(options, null, 2));
    
    const order = await razorpay.orders.create(options);
    console.log('Razorpay order created:', JSON.stringify(order, null, 2));
    return order;
  } catch (error) {
    console.error('Razorpay Create Order Error:', error);
    console.error('Error details:', JSON.stringify(error, null, 2));
    throw error;
  }
};

export const verifyPaymentSignature = (orderId, paymentId, signature) => {
  console.log('Verifying payment signature:', { orderId, paymentId, signature });
  
  const text = orderId + '|' + paymentId;
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(text.toString())
    .digest('hex');
  
  const isValid = expectedSignature === signature;
  console.log('Signature verification result:', isValid);
  
  return isValid;
};
