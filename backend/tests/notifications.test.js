const dispatchNotification = require('../src/services/dispatchNotification');
const db = require('../src/models/db');
const { sendPushNotification } = require('../src/services/notificationService');
const { sendSMS } = require('../src/services/smsService');

jest.mock('../src/models/db', () => ({
  query: jest.fn()
}));

jest.mock('../src/services/notificationService', () => ({
  sendPushNotification: jest.fn()
}));

jest.mock('../src/services/smsService', () => ({
  sendSMS: jest.fn()
}));

describe('Notifications Dispatch & Audit Trail Service', () => {
  let mockUser;

  beforeEach(() => {
    jest.clearAllMocks();
    mockUser = {
      phone_number: '+94771234567',
      full_name: 'Siri Perera'
    };
  });

  it('should return false if target user is not found in database', async () => {
    db.query.mockResolvedValueOnce({ rows: [] }); // User lookup returns empty

    const result = await dispatchNotification('user-uuid-1', 'booking-uuid-1', 'Title', 'Msg');
    expect(result).toBe(false);
    expect(db.query).toHaveBeenCalledWith(
      expect.stringContaining('SELECT phone_number'),
      ['user-uuid-1']
    );
  });

  it('should attempt push and fall back to SMS on failure, logging details in Postgres', async () => {
    db.query
      .mockResolvedValueOnce({ rows: [mockUser] }) // User lookup
      .mockResolvedValueOnce({}); // Log insert

    sendPushNotification.mockResolvedValueOnce(false); // Push fails
    sendSMS.mockResolvedValueOnce(true); // SMS fallback succeeds

    const result = await dispatchNotification('user-uuid-1', 'booking-uuid-1', 'Booking Confirmed', 'Your booking is ready');
    
    expect(result).toBe(true);
    expect(sendSMS).toHaveBeenCalledWith('+94771234567', 'Booking Confirmed: Your booking is ready');
    
    // Check that we inserted a log row with 'sms' channel and 'sent' delivery status
    expect(db.query).toHaveBeenLastCalledWith(
      expect.stringContaining('INSERT INTO notifications_log'),
      [
        'user-uuid-1',
        'booking-uuid-1',
        'sms',
        'Your booking is ready',
        'sent'
      ]
    );
  });

  it('should log status as failed if both push and SMS fallbacks fail', async () => {
    db.query
      .mockResolvedValueOnce({ rows: [mockUser] })
      .mockResolvedValueOnce({});

    sendPushNotification.mockResolvedValueOnce(false); // Push fails
    sendSMS.mockResolvedValueOnce(false); // SMS fails

    const result = await dispatchNotification('user-uuid-1', 'booking-uuid-1', 'Alert', 'Attention');
    
    expect(result).toBe(false);
    expect(db.query).toHaveBeenLastCalledWith(
      expect.stringContaining('INSERT INTO notifications_log'),
      [
        'user-uuid-1',
        'booking-uuid-1',
        'sms',
        'Attention',
        'failed'
      ]
    );
  });
});
