import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/machine.dart';
import 'machine_detail.dart';

class BrowseMachinesScreen extends StatefulWidget {
  const BrowseMachinesScreen({super.key});

  @override
  State<BrowseMachinesScreen> createState() => _BrowseMachinesScreenState();
}

class _BrowseMachinesScreenState extends State<BrowseMachinesScreen> {
  String? _selectedMachineType;
  String? _selectedGnDivision;
  String? _selectedPaddyType; // 'mud' or 'dry'
  DateTime? _selectedDate;

  List<Machine> _machines = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _allowedGnDivisions = [
    "Padaviya Town",
    "Aluth Halmillawa",
    "Ruwanpura",
    "1 Kanuwa",
    "A Yaya",
    "B Yaya",
    "C Yaya",
    "Maithreepura",
    "Budhdhangala",
    "Parakramapura",
    "Aliwanguwa",
    "Sripura"
  ];

  final Map<String, String> _machineTypes = {
    'four_wheel_tractor': 'Four-wheel Tractor',
    'four_wheel_tractor_with_trailer': 'Four-wheel Tractor with Trailer',
    'two_wheel_tractor': 'Two-wheel Tractor',
    'two_wheel_tractor_with_trailer': 'Two-wheel Tractor with Trailer',
    'combine_harvester': 'Combine Harvester',
  };

  @override
  void initState() {
    super.initState();
    _fetchMachines();
  }

  bool _isFieldTractor() {
    return _selectedMachineType == 'four_wheel_tractor' || _selectedMachineType == 'two_wheel_tractor';
  }

  Future<void> _fetchMachines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    // Build query params
    final List<String> queryParts = [];
    if (_selectedMachineType != null) {
      queryParts.add('machine_type=$_selectedMachineType');
    }
    if (_selectedGnDivision != null) {
      queryParts.add('gn_division=${Uri.encodeComponent(_selectedGnDivision!)}');
    }
    // (Paddy field type filtering can be applied client-side or backend, let's also pass it if backend supports or filter client-side)

    final path = queryParts.isEmpty ? '/machines' : '/machines?${queryParts.join('&')}';

    try {
      final response = await apiService.get(path);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Machine> list = data.map((json) => Machine.fromJson(json)).toList();

        // Client-side filter for paddy field type if needed
        if (_isFieldTractor() && _selectedPaddyType != null) {
          list = list.where((m) => m.paddyType == _selectedPaddyType).toList();
        }

        setState(() {
          _machines = list;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch machines: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Equipment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Machine Type Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        value: _selectedMachineType,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ..._machineTypes.entries.map((entry) {
                            return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedMachineType = val;
                            if (!_isFieldTractor()) {
                              _selectedPaddyType = null;
                            }
                          });
                          _fetchMachines();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // GN Division Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Division',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        value: _selectedGnDivision,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Padaviya')),
                          ..._allowedGnDivisions.map((div) {
                            return DropdownMenuItem(value: div, child: Text(div));
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedGnDivision = val);
                          _fetchMachines();
                        },
                      ),
                    ),
                  ],
                ),
                
                // Conditional Paddy Filter & Date Picker Row
                if (_isFieldTractor()) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Paddy Field Type',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          value: _selectedPaddyType,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Any Paddy')),
                            DropdownMenuItem(value: 'mud', child: Text('Mud Field')),
                            DropdownMenuItem(value: 'dry', child: Text('Dry Field')),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedPaddyType = val);
                            _fetchMachines();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              _fetchMachines();
                            }
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade800,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    : _machines.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching machines found in Padaviya.\nTry broadening your search filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMachines,
                            child: ListView.builder(
                              itemCount: _machines.length,
                              itemBuilder: (context, idx) {
                                final m = _machines[idx];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: m.photoUrl != null
                                          ? Image.network(m.photoUrl!, fit: BoxFit.cover)
                                          : const Icon(Icons.agriculture, color: Colors.green, size: 36),
                                    ),
                                    title: Text(
                                      m.modelName ?? _machineTypes[m.machineType] ?? m.machineType,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Type: ${_machineTypes[m.machineType]}'),
                                        if (m.paddyType != null)
                                          Text(
                                            'Paddy: ${m.paddyType == 'mud' ? 'Mud Field' : 'Dry Field'}',
                                            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                          ),
                                        Text('Service divisions: ${m.serviceGnDivisions.join(", ")}'),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'LKR ${m.rateAmount.toInt()}/${m.rateUnit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 2),
                                            Text(
                                              '4.5', // Stubbed rating for visual representation
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MachineDetailScreen(machine: m),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
