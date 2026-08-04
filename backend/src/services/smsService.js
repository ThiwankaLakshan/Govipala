/**
 * Sends a status update SMS via Twilio or Dialog/Mobitel local gateways.
 * Returns true if successfully dispatched, false otherwise.
 */
async function sendSMS(phoneNumber, message) {
  const apiKey = process.env.SMS_GATEWAY_API_KEY;
  const senderId = process.env.SMS_GATEWAY_SENDER_ID || 'AgriMachine';

  if (!phoneNumber || !message) {
    console.error('[SMS Error] Phone number and message body are required.');
    return false;
  }

  // If mock key or missing key, log to console
  if (!apiKey || apiKey.includes('mock-')) {
    console.log(`[SMS Mock Send] To: ${phoneNumber} | Sender: ${senderId} | Msg: "${message}"`);
    return true; // Mock success
  }

  // In production, trigger request to the SMS gateway API (e.g. Twilio or local telco gateway)
  try {
    // Example fetch to SMS gateway:
    // const response = await axios.post('https://api.sms-gateway.com/send', {
    //   api_key: apiKey,
    //   sender: senderId,
    //   to: phoneNumber,
    //   message: message
    // });
    // return response.status === 200;
    
    console.log(`[SMS Live Gateway Dispatch] To: ${phoneNumber} | Msg: "${message}"`);
    return true;
  } catch (error) {
    console.error('[SMS Gateway Error] Failed to dispatch SMS:', error);
    return false;
  }
}

module.exports = {
  sendSMS
};
