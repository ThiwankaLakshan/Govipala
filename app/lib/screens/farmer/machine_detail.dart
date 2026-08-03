import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/machine.dart';
import '../../models/availability_slot.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MachineDetailScreen extends StatefulWidget {
  final Machine machine;

  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  List<AvailabilitySlot> _slots = [];
  List<dynamic> _reviews = [];
  bool _isLoadingSlots = false;
  bool _isLoadingReviews = false;
  
  // Dialog form controllers
  final _landLocationController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const Map<String, String> _machineTypes = {
    'four_wheel_tractor': 'Four-wheel Tractor',
    'four_wheel_tractor_with_trailer': 'Four-wheel Tractor with Trailer',
    'two_wheel_tractor': 'Two-wheel Tractor',
    'two_wheel_tractor_with_trailer': 'Two-wheel Tractor with Trailer',
    'combine_harvester': 'Combine Harvester',
  };

  @override
  void initState() {
    super.initState();
    _fetchSlots();
    _fetchReviews();
  }

  @override
  void dispose() {
    _landLocationController.dispose();
    _landSizeController.dispose();
    super.dispose();
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  Future<void> _fetchSlots() async {
    setState(() => _isLoadingSlots = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    final now = DateTime.now();
    final fromDate = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    final future = now.add(const Duration(days: 30));
    final toDate = '${future.year}-${_pad(future.month)}-${_pad(future.day)}';

    try {
      final response = await apiService.get(
        '/machines/${widget.machine.id}/availability?from=$fromDate&to=$toDate',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _slots = data
              .map((j) => AvailabilitySlot.fromJson(j))
              .where((s) => s.status == 'open') // Only display open slots to farmers
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.get('/reviews/machines/${widget.machine.id}');
      if (response.statusCode == 200) {
        setState(() {
          _reviews = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching machine reviews: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _requestBooking(String slotId) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    final body = {
      'slot_id': slotId,
      'land_location': _landLocationController.text.trim().isEmpty ? null : _landLocationController.text.trim(),
      'land_size_acres': double.parse(_landSizeController.text.trim()),
    };

    try {
      final response = await apiService.post('/bookings', body);
      
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request successfully submitted!')),
        );
        Navigator.pop(context); // Close dialog
        _fetchSlots(); // Refresh slot list
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conflict: This slot is no longer available. Refreshing slots.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        _fetchSlots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  void _showBookingDialog(AvailabilitySlot slot) {
    _landLocationController.clear();
    _landSizeController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Book slot: ${slot.slotDate}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Time: ${slot.startTime} - ${slot.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landSizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Land Area (Acres) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    final double? d = double.tryParse(val);
                    if (d == null || d <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _landLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _requestBooking(slot.id),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeName = _machineTypes[widget.machine.machineType] ?? widget.machine.machineType;
    final isTractor = ['four_wheel_tractor', 'two_wheel_tractor'].contains(widget.machine.machineType);
    final averageRating = widget.machine.averageRating ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machine.modelName ?? typeName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Machine photo or placeholder
            Container(
              height: 220,
              color: Colors.green.shade100,
              child: widget.machine.photoUrl != null
                  ? Image.network(widget.machine.photoUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.agriculture, color: Colors.green, size: 80),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.machine.modelName ?? typeName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.machine.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.machine.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: widget.machine.isActive ? Colors.green.shade800 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Machine Type and Owner Name/Rating Row
                  Row(
                    children: [
                      Text(
                        typeName,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      if (averageRating > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        const Text('No reviews', style: TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                  if (widget.machine.ownerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Listed by: ${widget.machine.ownerName}',
                      style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Rate Card
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rental Rate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'LKR ${widget.machine.rateAmount.toInt()} / ${widget.machine.rateUnit}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tractor specific details
                  if (isTractor && widget.machine.paddyType != null) ...[
                    const Text(
                      'Paddy Field Suitability',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          widget.machine.paddyType == 'mud' ? Icons.water : Icons.landscape,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.machine.paddyType == 'mud'
                              ? 'Mud Field (Wet land preparation)'
                              : 'Dry Field (Dry land preparation)',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                  ],

                  // Service areas
                  const Text(
                    'Operating Service Divisions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.machine.serviceGnDivisions.map((div) {
                      return Chip(
                        label: Text(div),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(color: Colors.grey.shade300),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 30),

                  // Available Slots Section
                  const Text(
                    'Available Date & Time Slots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (_slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No open availability slots published for this machine.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slots.length,
                      itemBuilder: (context, idx) {
                        final slot = _slots[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(slot.slotDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                            trailing: ElevatedButton(
                              onPressed: () => _showBookingDialog(slot),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const Divider(height: 40),

                  // Reviews List Section
                  const Text(
                    'Reviews & Feedback',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No customer reviews written yet.',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, idx) {
                        final rev = _reviews[idx];
                        final double rVal = double.parse(rev['rating'].toString());

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rev['reviewer_name'] ?? 'Anonymous Farmer',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        return Icon(
                                          starIdx < rVal ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                if (rev['comment'] != null && rev['comment'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${rev['comment']}"',
                                    style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
