import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/machine.dart';
import '../../models/availability_slot.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  List<Machine> _myMachines = [];
  Machine? _selectedMachine;
  List<AvailabilitySlot> _slots = [];
  bool _isLoading = false;

  // Add slot form controllers
  DateTime? _slotDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _fetchMyMachines();
  }

  Future<void> _fetchMyMachines() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      // Mock lookup: Fetch owner machines
      final response = await apiService.get('/machines'); // Normally would query ?owner=me or backend filters active listings
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((j) => Machine.fromJson(j)).toList();
        setState(() {
          _myMachines = list;
          if (_myMachines.isNotEmpty) {
            _selectedMachine = _myMachines.first;
            _fetchSlots();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching machines: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSlots() async {
    if (_selectedMachine == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    // Date range of 30 days
    final now = DateTime.now();
    final fromDate = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    final future = now.add(const Duration(days: 30));
    final toDate = '${future.year}-${_pad(future.month)}-${_pad(future.day)}';

    try {
      final response = await apiService.get(
        '/machines/${_selectedMachine!.id}/availability?from=$fromDate&to=$toDate',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _slots = data.map((j) => AvailabilitySlot.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  Future<void> _createSlot() async {
    if (_selectedMachine == null || _slotDate == null || _startTime == null || _endTime == null) return;

    final startStr = '${_pad(_startTime!.hour)}:${_pad(_startTime!.minute)}';
    final endStr = '${_pad(_endTime!.hour)}:${_pad(_endTime!.minute)}';

    if (startStr.compareTo(endStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    final body = {
      'slots': [
        {
          'slot_date': '${_slotDate!.year}-${_pad(_slotDate!.month)}-${_pad(_slotDate!.day)}',
          'start_time': startStr,
          'end_time': endStr,
        }
      ]
    };

    try {
      final response = await apiService.post(
        '/machines/${_selectedMachine!.id}/availability',
        body,
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot added successfully!')),
        );
        _fetchSlots();
        Navigator.pop(context); // Close dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.delete('/availability/$slotId');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted')),
        );
        _fetchSlots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddSlotDialog() {
    _slotDate = null;
    _startTime = null;
    _endTime = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Availability Slot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      _slotDate == null
                          ? 'Select Date'
                          : '${_slotDate!.year}-${_slotDate!.month}-${_slotDate!.day}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setDialogState(() => _slotDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      _startTime == null
                          ? 'Select Start Time'
                          : '${_startTime!.hour}:${_pad(_startTime!.minute)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() => _startTime = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      _endTime == null
                          ? 'Select End Time'
                          : '${_endTime!.hour}:${_pad(_endTime!.minute)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() => _endTime = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _createSlot,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'booked':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Setup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Machine Selector
                if (_myMachines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: DropdownButtonFormField<Machine>(
                      decoration: const InputDecoration(
                        labelText: 'Select Equipment',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedMachine,
                      items: _myMachines.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.modelName ?? m.machineType),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMachine = val;
                          _slots.clear();
                        });
                        _fetchSlots();
                      },
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Register a machine listing first to manage slots'),
                  ),

                // Slots list
                Expanded(
                  child: _slots.isEmpty
                      ? const Center(child: Text('No slots configured. Tap "+" to add open slots.'))
                      : ListView.builder(
                          itemCount: _slots.length,
                          itemBuilder: (context, idx) {
                            final slot = _slots[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(slot.status),
                                  radius: 8,
                                ),
                                title: Text('${slot.slotDate} (${slot.status.toUpperCase()})'),
                                subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                                trailing: slot.status == 'open'
                                    ? IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSlot(slot.id),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedMachine != null
          ? FloatingActionButton(
              onPressed: _showAddSlotDialog,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
