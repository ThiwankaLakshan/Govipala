import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class AddMachineScreen extends StatefulWidget {
  const AddMachineScreen({super.key});

  @override
  State<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends State<AddMachineScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _machineType;
  String? _paddyType;
  final _modelNameController = TextEditingController();
  final _rateAmountController = TextEditingController();
  String _rateUnit = 'day';
  final _photoUrlController = TextEditingController();
  
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
  
  final List<String> _selectedGnDivisions = [];
  bool _isLoading = false;

  static const Map<String, String> _machineTypes = {
    'four_wheel_tractor': 'Four-wheel Tractor',
    'four_wheel_tractor_with_trailer': 'Four-wheel Tractor with Trailer',
    'two_wheel_tractor': 'Two-wheel Tractor',
    'two_wheel_tractor_with_trailer': 'Two-wheel Tractor with Trailer',
    'combine_harvester': 'Combine Harvester',
  };

  @override
  void dispose() {
    _modelNameController.dispose();
    _rateAmountController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  bool _isFieldTractor() {
    return _machineType == 'four_wheel_tractor' || _machineType == 'two_wheel_tractor';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGnDivisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one GN Division for service area')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    final Map<String, dynamic> body = {
      'machine_type': _machineType,
      'model_name': _modelNameController.text.trim().isEmpty ? null : _modelNameController.text.trim(),
      'rate_amount': double.parse(_rateAmountController.text),
      'rate_unit': _rateUnit,
      'photo_url': _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
      'service_gn_divisions': _selectedGnDivisions,
    };

    if (_isFieldTractor()) {
      body['paddy_type'] = _paddyType;
    }

    try {
      final response = await apiService.post('/machines', body);
      
      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine listing successfully registered!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Machine'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Register Agricultural Equipment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    
                    // Machine Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Machine Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _machineType,
                      items: _machineTypes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _machineType = val;
                          if (!_isFieldTractor()) {
                            _paddyType = null;
                          }
                        });
                      },
                      validator: (val) => val == null ? 'Machine Type is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Conditional Paddy Suitability Selector
                    if (_isFieldTractor()) ...[
                      const Text(
                        'Paddy Suitability',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Mud Field'),
                              value: 'mud',
                              groupValue: _paddyType,
                              onChanged: (val) => setState(() => _paddyType = val),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Dry Field'),
                              value: 'dry',
                              groupValue: _paddyType,
                              onChanged: (val) => setState(() => _paddyType = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Model Name
                    TextFormField(
                      controller: _modelNameController,
                      decoration: const InputDecoration(
                        labelText: 'Model Name (e.g. Massey Ferguson 240)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rate settings
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _rateAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Rate Amount (LKR)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              final double? valDouble = double.tryParse(val);
                              if (valDouble == null || valDouble <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Per Unit',
                              border: OutlineInputBorder(),
                            ),
                            value: _rateUnit,
                            items: const [
                              DropdownMenuItem(value: 'hour', child: Text('Hour')),
                              DropdownMenuItem(value: 'day', child: Text('Day')),
                              DropdownMenuItem(value: 'acre', child: Text('Acre')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _rateUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Image Url input
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo URL (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),

                    // GN Service Area checklist
                    const Text(
                      'Service Divisions (Select where you can operate)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allowedGnDivisions.length,
                        itemBuilder: (context, idx) {
                          final div = _allowedGnDivisions[idx];
                          return CheckboxListTile(
                            title: Text(div),
                            dense: true,
                            value: _selectedGnDivisions.contains(div),
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedGnDivisions.add(div);
                                } else {
                                  _selectedGnDivisions.remove(div);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Register Machine', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
