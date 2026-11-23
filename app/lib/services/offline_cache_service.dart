import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/machine.dart';
import '../models/availability_slot.dart';
import '../models/offline_queue.dart';
import 'api_service.dart';

export '../models/offline_queue.dart';

class OfflineCacheService {
  static const String _keyMachines = 'govi_cache_machines';
  static const String _keySlotsPrefix = 'govi_cache_slots_';
  static const String _keyQueuedBookings = 'govi_queued_bookings';

  static final ValueNotifier<ConnectionStateStatus> connectionStatus =
      ValueNotifier<ConnectionStateStatus>(ConnectionStateStatus.online);

  static void setConnectionStatus(ConnectionStateStatus status) {
    connectionStatus.value = status;
    if (status == ConnectionStateStatus.online) {
      syncQueuedBookings();
    }
  }

  /// FR-8.1: Cache machines list locally
  static Future<void> cacheMachines(List<MachineModel> machines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = machines.map((m) => m.toJson()).toList();
      await prefs.setString(_keyMachines, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching machines: $e');
    }
  }

  /// FR-8.1: Retrieve cached machines
  static Future<List<MachineModel>> getCachedMachines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyMachines);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => MachineModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached machines: $e');
    }
    return [];
  }

  /// FR-8.1: Cache availability slots for a machine
  static Future<void> cacheSlots(String machineId, List<AvailabilitySlotModel> slots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = slots.map((s) => s.toJson()).toList();
      await prefs.setString('$_keySlotsPrefix$machineId', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching slots: $e');
    }
  }

  /// FR-8.1: Retrieve cached slots
  static Future<List<AvailabilitySlotModel>> getCachedSlots(String machineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keySlotsPrefix$machineId');
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => AvailabilitySlotModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached slots: $e');
    }
    return [];
  }

  /// FR-8.2: Queue booking request while offline
  static Future<void> queueBooking({
    required String slotId,
    required String landLocation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = await getQueuedBookings();
      queued.add(QueuedBooking(
        id: 'queued-${DateTime.now().millisecondsSinceEpoch}',
        slotId: slotId,
        landLocation: landLocation,
        createdAt: DateTime.now(),
      ));

      final jsonList = queued.map((q) => q.toJson()).toList();
      await prefs.setString(_keyQueuedBookings, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error queuing booking: $e');
    }
  }

  /// FR-8.2: Get queued offline bookings
  static Future<List<QueuedBooking>> getQueuedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyQueuedBookings);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => QueuedBooking.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error reading queued bookings: $e');
    }
    return [];
  }

  /// FR-8.2: Automatically sync queued booking requests upon reconnection
  static Future<int> syncQueuedBookings() async {
    final queued = await getQueuedBookings();
    if (queued.isEmpty) return 0;

    connectionStatus.value = ConnectionStateStatus.syncing;
    int syncedCount = 0;
    final remaining = <QueuedBooking>[];

    for (final item in queued) {
      try {
        await ApiService.createBooking(
          slotId: item.slotId,
          landLocation: item.landLocation,
        );
        syncedCount++;
      } catch (e) {
        // If conflict or failure, keep or log
        debugPrint('Sync booking failed for ${item.id}: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (remaining.isEmpty) {
        await prefs.remove(_keyQueuedBookings);
      } else {
        await prefs.setString(
          _keyQueuedBookings,
          jsonEncode(remaining.map((r) => r.toJson()).toList()),
        );
      }
    } catch (_) {}

    connectionStatus.value = ConnectionStateStatus.online;
    return syncedCount;
  }
}
