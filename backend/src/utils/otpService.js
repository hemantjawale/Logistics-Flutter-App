import twilio from 'twilio';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID; // Or Verify Service SID if using Verify API

// For this implementation, we'll use Twilio Programmable Messaging to send a random code
// In production, Twilio Verify API is recommended for OTPs.
// Assuming user wants simple SMS with code for now.

const client = twilio(accountSid, authToken);
const otps = new Map(); // Store OTPs in memory (production: use Redis)

export const sendOtp = async (phone) => {
  // Generate 6 digit code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Store OTP with expiration (5 mins)
  otps.set(phone, { code, expires: Date.now() + 5 * 60 * 1000 });

  try {
    await client.messages.create({
      body: `Your Logistics App verification code is: ${code}`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone
    });
    return true;
  } catch (error) {
    console.error('Twilio Error:', error);
    throw new Error('Failed to send OTP');
  }
};

export const verifyOtp = (phone, code) => {
  const data = otps.get(phone);
  if (!data) return false;
  if (Date.now() > data.expires) {
    otps.delete(phone);
    return false;
  }
  if (data.code === code) {
    otps.delete(phone);
    return true;
  }
  return false;
};
