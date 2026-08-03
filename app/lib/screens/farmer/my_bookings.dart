import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _myBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyBookings();
  }

  Future<void> _fetchMyBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.get('/bookings/mine?as=farmer');
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          _myBookings = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load bookings: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.patch(
        '/bookings/$bookingId/status',
        {
          'status': 'cancelled',
          'cancellation_reason': 'Cancelled by Farmer'
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successfully cancelled.')),
        );
        _fetchMyBookings();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancellation failed: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showReviewDialog(String bookingId) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate your experience'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select rating (1-5 stars):'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final starVal = idx + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = starVal);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comments (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitReview(bookingId, rating, commentController.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(String bookingId, int rating, String comment) async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.post('/reviews', {
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment.trim().isEmpty ? null : comment.trim(),
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully! Thank you.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _myBookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _myBookings.isEmpty
                  ? const Center(
                      child: Text(
                        'You have not made any booking requests yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyBookings,
                      child: ListView.builder(
                        itemCount: _myBookings.length,
                        itemBuilder: (context, idx) {
                          final b = _myBookings[idx];
                          final bool canCancel = ['requested', 'confirmed'].contains(b['status']);
                          final bool isCompleted = b['status'] == 'completed';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        b['model_name'] ?? b['machine_type'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(b['status']).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          b['status'].toString().toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(b['status']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Owner: ${b['owner_name'] ?? 'Anonymous'}'),
                                  Text('Date: ${b['slot_date']} (${b['start_time']} - ${b['end_time']})'),
                                  Text('Acreage: ${b['land_size_acres']} Acres', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (b['land_location'] != null)
                                    Text('Location: ${b['land_location']}'),
                                  if (b['cancellation_reason'] != null)
                                    Text(
                                      'Cancellation Reason: ${b['cancellation_reason']}',
                                      style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                                    ),
                                  
                                  // Action Buttons
                                  if (canCancel || isCompleted) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (canCancel)
                                          OutlinedButton.icon(
                                            onPressed: () => _cancelBooking(b['id']),
                                            icon: const Icon(Icons.cancel, size: 18),
                                            label: const Text('Cancel Booking'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                          ),
                                        if (isCompleted)
                                          ElevatedButton.icon(
                                            onPressed: () => _showReviewDialog(b['id']),
                                            icon: const Icon(Icons.rate_review),
                                            label: const Text('Leave Review'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
