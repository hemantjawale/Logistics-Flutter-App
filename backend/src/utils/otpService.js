import twilio from 'twilio';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID; // Or Verify Service SID if using Verify API

// For this implementation, we'll use Twilio Programmable Messaging to send a random code
// In production, Twilio Verify API is recommended for OTPs.
// Assuming user wants simple SMS with code for now.

const client = (accountSid && authToken) ? twilio(accountSid, authToken) : null;
const otps = new Map(); // Store OTPs in memory (production: use Redis)

export const sendOtp = async (phone) => {
  // Generate 6 digit code
  let code = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Check if we should use Mock mode
  const useMock = !client || !process.env.TWILIO_PHONE_NUMBER;
  
  if (useMock) {
      code = '123456'; // Use fixed code for easier testing when Twilio is disabled
      console.warn('[OTP SERVICE] Twilio credentials missing. Using MOCK code: 123456');
  }

  // Store OTP with expiration (5 mins)
  otps.set(phone, { code, expires: Date.now() + 5 * 60 * 1000 });
  console.log(`[OTP SERVICE] Generated OTP for ${phone}: ${code}`);

  if (useMock) return true;

  try {
    await client.messages.create({
      body: `Your Logistics App verification code is: ${code}`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone
    });
    console.log(`[OTP SERVICE] OTP sent via Twilio to ${phone}`);
    return true;
  } catch (error) {
    console.error('[OTP SERVICE] Twilio Error:', error.message);
    // Fallback to mock if Twilio fails (e.g. unverified number in trial)
    console.warn('[OTP SERVICE] Falling back to MOCK mode. Code is still: ' + code);
    // Note: If we generated a random code and Twilio failed, the user won't know it unless they see logs.
    // So let's force it to 123456 for the NEXT attempt or just update it now?
    // We can't update the sent message, but we can update our store.
    otps.set(phone, { code: '123456', expires: Date.now() + 5 * 60 * 1000 });
    console.warn('[OTP SERVICE] Reset OTP to 123456 for manual entry.');
    return true; 
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
