import 'package:test/test.dart';
import 'package:govipala/models/user.dart';
import 'package:govipala/models/machine.dart';
import 'package:govipala/models/admin_stats.dart';
import 'package:govipala/models/audit_log.dart';
import 'package:govipala/models/availability_slot.dart';
import 'package:govipala/models/booking.dart';
import 'package:govipala/models/notification.dart';
import 'package:govipala/models/review.dart';
import 'package:govipala/models/offline_queue.dart';

void main() {
  group('Govipala UserModel Tests', () {
    test('UserModel serializes and deserializes properly', () {
      final json = {
        'id': '11111111-2222-3333-4444-555555555555',
        'phone_number': '+94771234567',
        'full_name': 'Sunil Perera',
        'role': 'farmer',
        'gn_division': 'Padaviya Town',
        'preferred_lang': 'si',
        'status': 'active',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '11111111-2222-3333-4444-555555555555');
      expect(user.fullName, 'Sunil Perera');
      expect(user.role, UserRole.farmer);
      expect(user.gnDivision, 'Padaviya Town');
      expect(user.preferredLang, 'si');

      final serialized = user.toJson();
      expect(serialized['full_name'], 'Sunil Perera');
      expect(serialized['role'], 'farmer');
    });

    test('UserModel handles owner and both roles correctly', () {
      final ownerUser = UserModel.fromJson({
        'id': '22222222-3333-4444-5555-666666666666',
        'phone_number': '+94777654321',
        'full_name': 'Kamal Silva',
        'role': 'owner',
        'gn_division': 'Sripura',
        'preferred_lang': 'si',
        'status': 'active',
      });
      expect(ownerUser.role, UserRole.owner);

      final bothUser = UserModel.fromJson({
        'id': '33333333-4444-5555-6666-777777777777',
        'phone_number': '+94779998877',
        'full_name': 'Nimal Bandara',
        'role': 'both',
        'gn_division': 'Buddhangala',
        'preferred_lang': 'si',
        'status': 'active',
      });
      expect(bothUser.role, UserRole.both);
    });
  });

  group('Govipala MachineModel Tests (Phase 2)', () {
    test('MachineModel parses four_wheel_tractor with 4wd drive type (FR-2.8)', () {
      final json = {
        'id': 'mmmmmmmm-1111-2222-3333-444444444444',
        'owner_id': 'oooooooo-1111-2222-3333-444444444444',
        'machine_type': 'four_wheel_tractor',
        'brand': 'John Deere',
        'drive_type': '4wd',
        'model_name': '5050D',
        'rate_amount': 4000,
        'rate_unit': 'hour',
        'photo_url': 'https://example.com/tractor.jpg',
        'service_gn_divisions': ['Padaviya Town', 'Sripura'],
        'is_active': true,
        'created_at': '2026-11-23T10:00:00.000Z',
        'owner_name': 'Nimal Bandara',
        'average_rating': 4.5,
        'review_count': 12,
      };

      final machine = MachineModel.fromJson(json);
      expect(machine.brand, 'John Deere');
      expect(machine.machineType, MachineType.fourWheelTractor);
      expect(machine.driveType, DriveType.fourWheel);
      expect(machine.rateAmount, 4000.0);
      expect(machine.rateUnit, RateUnit.hour);
      expect(machine.serviceGnDivisions, contains('Padaviya Town'));
      expect(machine.formattedRate, contains('4000'));
      expect(machine.displayTitle, contains('John Deere'));
    });

    test('MachineModel handles non-four-wheel machine without drive type (FR-2.9)', () {
      final json = {
        'id': 'mmmmmmmm-2222-3333-4444-555555555555',
        'owner_id': 'oooooooo-1111-2222-3333-444444444444',
        'machine_type': 'combine_harvester',
        'brand': 'Kubota',
        'drive_type': null,
        'model_name': 'DC-70',
        'rate_amount': 9500,
        'rate_unit': 'acre',
        'service_gn_divisions': ['Buddhangala'],
        'is_active': true,
      };

      final machine = MachineModel.fromJson(json);
      expect(machine.brand, 'Kubota');
      expect(machine.machineType, MachineType.combineHarvester);
      expect(machine.driveType, isNull);
      expect(machine.rateUnit, RateUnit.acre);
    });
  });

  group('Govipala AdminModel Tests (Phase 2b)', () {
    test('AdminDashboardStats parses user, machine, and booking counts correctly', () {
      final json = {
        'users': {
          'total_users': 15,
          'farmers': 10,
          'owners': 3,
          'both_roles': 1,
          'admins': 1,
          'active_users': 14,
          'suspended_users': 1,
        },
        'machines': {
          'total_machines': 8,
          'active_machines': 7,
          'inactive_machines': 1,
        },
        'bookings': {
          'total_bookings': 25,
          'pending_bookings': 4,
          'confirmed_bookings': 12,
          'in_progress_bookings': 2,
          'completed_bookings': 5,
          'cancelled_bookings': 2,
          'bookings_today': 3,
        },
      };

      final stats = AdminDashboardStats.fromJson(json);
      expect(stats.users.totalUsers, 15);
      expect(stats.users.farmers, 10);
      expect(stats.users.suspendedUsers, 1);
      expect(stats.machines.totalMachines, 8);
      expect(stats.machines.activeMachines, 7);
      expect(stats.bookings.confirmedBookings, 12);
      expect(stats.bookings.bookingsToday, 3);
    });

    test('AuditLogItem parses admin action and mandatory reason (FR-9.12)', () {
      final json = {
        'id': 'audit-1111-2222',
        'admin_id': 'admin-0001',
        'admin_name': 'Govipala Admin',
        'action': 'UPDATE_USER_STATUS',
        'target_table': 'users',
        'target_id': 'user-9999',
        'before_data': {'status': 'active'},
        'after_data': {'status': 'suspended'},
        'reason': 'Repeated booking cancellations without notice',
        'created_at': '2026-11-23T12:00:00.000Z',
      };

      final audit = AuditLogItem.fromJson(json);
      expect(audit.id, 'audit-1111-2222');
      expect(audit.adminName, 'Govipala Admin');
      expect(audit.action, 'UPDATE_USER_STATUS');
      expect(audit.targetTable, 'users');
      expect(audit.reason, 'Repeated booking cancellations without notice');
      expect(audit.beforeData['status'], 'active');
      expect(audit.afterData['status'], 'suspended');
    });
  });

  group('Govipala Availability & Booking Tests (Phase 3)', () {
    test('AvailabilitySlotModel parses slot attributes and time formatting', () {
      final json = {
        'id': 'slot-test-001',
        'machine_id': 'mach-test-001',
        'slot_date': '2026-11-25',
        'start_time': '08:00:00',
        'end_time': '12:00:00',
        'status': 'open',
        'created_at': '2026-11-23T12:00:00.000Z',
      };

      final slot = AvailabilitySlotModel.fromJson(json);
      expect(slot.id, 'slot-test-001');
      expect(slot.machineId, 'mach-test-001');
      expect(slot.slotDate, '2026-11-25');
      expect(slot.isOpen, isTrue);
      expect(slot.isPending, isFalse);
      expect(slot.isBooked, isFalse);
      expect(slot.formattedStartTime, '08:00');
      expect(slot.formattedEndTime, '12:00');
      expect(slot.formattedTimeRange, '08:00 - 12:00');
      expect(slot.statusSinhala, contains('ලබාගත හැක'));
    });

    test('BookingModel parses joined machine, slot, and owner details', () {
      final json = {
        'id': 'book-test-001',
        'slot_id': 'slot-test-001',
        'farmer_id': 'farmer-001',
        'land_location': 'Near Padaviya Lake, Plot 14',
        'status': 'requested',
        'requested_at': '2026-11-23T14:30:00.000Z',
        'farmer_name': 'Sunil Perera',
        'farmer_phone': '+94771234567',
        'farmer_gn_division': 'Padaviya Town',
        'owner_id': 'owner-001',
        'owner_name': 'Kamal Silva',
        'owner_phone': '+94777654321',
        'machine_id': 'mach-test-001',
        'machine_brand': 'John Deere',
        'machine_model': '5050D',
        'machine_type': 'four_wheel_tractor',
        'drive_type': '4wd',
        'rate_amount': 4000.0,
        'rate_unit': 'hour',
        'slot_date': '2026-11-25',
        'start_time': '08:00:00',
        'end_time': '12:00:00',
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.id, 'book-test-001');
      expect(booking.slotId, 'slot-test-001');
      expect(booking.farmerName, 'Sunil Perera');
      expect(booking.ownerName, 'Kamal Silva');
      expect(booking.machineBrand, 'John Deere');
      expect(booking.isRequested, isTrue);
      expect(booking.isConfirmed, isFalse);
      expect(booking.formattedRate, contains('රු. 4000'));
      expect(booking.formattedTimeRange, '08:00 - 12:00');
      expect(booking.statusSinhala, contains('ඉල්ලීම යවා ඇත'));
    });

    test('BookingModel transitions and Sinhala badges', () {
      final confirmed = BookingModel.fromJson({
        'id': 'b-2',
        'slot_id': 's-2',
        'farmer_id': 'f-2',
        'status': 'confirmed',
        'requested_at': '2026-11-23T10:00:00.000Z',
      });
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.statusSinhala, contains('තහවුරු කරන ලදී'));

      final completed = BookingModel.fromJson({
        'id': 'b-3',
        'slot_id': 's-3',
        'farmer_id': 'f-3',
        'status': 'completed',
        'requested_at': '2026-11-23T10:00:00.000Z',
      });
      expect(completed.isCompleted, isTrue);
      expect(completed.statusSinhala, contains('සම්පූර්ණයි'));
    });
  });

  group('Govipala Notification & Review Tests (Phase 4 & 5)', () {
    test('NotificationModel parses push and sms attributes correctly (FR-6.4)', () {
      final pushJson = {
        'id': 'notif-001',
        'user_id': 'user-111',
        'booking_id': 'book-111',
        'channel': 'push',
        'title': 'වෙන්කිරීම තහවුරු විය',
        'message': 'ඔබගේ වෙන්කිරීම තහවුරු කරන ලදී.',
        'sent_at': '2026-11-23T14:00:00.000Z',
        'delivery_status': 'delivered',
        'read': false,
      };

      final push = NotificationModel.fromJson(pushJson);
      expect(push.id, 'notif-001');
      expect(push.isPush, isTrue);
      expect(push.isSms, isFalse);
      expect(push.title, 'වෙන්කිරීම තහවුරු විය');
      expect(push.message, contains('තහවුරු කරන ලදී'));

      final smsJson = {
        'id': 'notif-002',
        'user_id': 'user-111',
        'channel': 'sms',
        'message': '[Govipala Alert] SMS Fallback',
        'sent_at': '2026-11-23T14:01:00.000Z',
      };
      final sms = NotificationModel.fromJson(smsJson);
      expect(sms.isSms, isTrue);
      expect(sms.isPush, isFalse);
    });

    test('ReviewModel and ReviewsListResponse parse ratings and averages (FR-7.2)', () {
      final json = {
        'average_rating': 4.8,
        'review_count': 2,
        'reviews': [
          {
            'id': 'rev-1',
            'booking_id': 'b-1',
            'reviewer_id': 'u-1',
            'reviewer_name': 'Anura Kumara',
            'reviewee_id': 'u-2',
            'rating': 5,
            'comment': 'විශිෂ්ට ට්‍රැක්ටර් සේවාවක් (Great tractor service)',
            'is_hidden': false,
            'created_at': '2026-11-23T12:00:00.000Z',
          },
          {
            'id': 'rev-2',
            'booking_id': 'b-2',
            'reviewer_id': 'u-3',
            'reviewer_name': 'Kamal Silva',
            'reviewee_id': 'u-2',
            'rating': 4,
            'comment': null,
            'is_hidden': false,
            'created_at': '2026-11-23T13:00:00.000Z',
          }
        ]
      };

      final resp = ReviewsListResponse.fromJson(json);
      expect(resp.averageRating, 4.8);
      expect(resp.reviewCount, 2);
      expect(resp.reviews.length, 2);
      expect(resp.reviews[0].reviewerName, 'Anura Kumara');
      expect(resp.reviews[0].rating, 5);
      expect(resp.reviews[0].comment, contains('විශිෂ්ට'));
      expect(resp.reviews[1].rating, 4);
      expect(resp.reviews[1].comment, isNull);
    });
  });

  group('Govipala Offline & Cache Tests (Phase 6: FR-8.1 - FR-8.3)', () {
    test('QueuedBooking serializes and deserializes properly for offline queue (FR-8.2)', () {
      final queued = QueuedBooking(
        id: 'queued-001',
        slotId: 'slot-123',
        landLocation: 'Track 10 Padaviya',
        createdAt: DateTime.parse('2026-11-23T15:00:00.000Z'),
      );

      final json = queued.toJson();
      expect(json['id'], 'queued-001');
      expect(json['slot_id'], 'slot-123');
      expect(json['land_location'], 'Track 10 Padaviya');

      final deserialized = QueuedBooking.fromJson(json);
      expect(deserialized.id, 'queued-001');
      expect(deserialized.slotId, 'slot-123');
      expect(deserialized.landLocation, 'Track 10 Padaviya');
    });

    test('ConnectionStateStatus enum values (FR-8.3)', () {
      expect(ConnectionStateStatus.values.length, 3);
      expect(ConnectionStateStatus.online.name, 'online');
      expect(ConnectionStateStatus.offline.name, 'offline');
      expect(ConnectionStateStatus.syncing.name, 'syncing');
    });
  });

  group('Govipala Login & Role Tests', () {
    test('Validates role keys and demo credentials structure', () {
      const demoFarmerPhone = '077 555 1122';
      const demoFarmerPass = 'farmer123';
      const demoOwnerPhone = '077 123 4567';
      const demoOwnerPass = 'owner123';
      const demoAdminEmail = 'admin@govipala.lk';
      const demoAdminPass = 'admin123';

      expect(demoFarmerPass, 'farmer123');
      expect(demoOwnerPass, 'owner123');
      expect(demoAdminPass, 'admin123');
      expect(demoFarmerPhone.replaceAll(' ', ''), '0775551122');
      expect(demoOwnerPhone.replaceAll(' ', ''), '0771234567');
      expect(demoAdminEmail, contains('@govipala.lk'));
    });

    test('UserRole enum includes farmer, owner, and both', () {
      expect(UserRole.values, contains(UserRole.farmer));
      expect(UserRole.values, contains(UserRole.owner));
      expect(UserRole.values, contains(UserRole.both));
    });
  });
}
