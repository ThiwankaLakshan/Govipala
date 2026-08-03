import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterProfileScreen extends StatefulWidget {
  const RegisterProfileScreen({super.key});

  @override
  State<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedRole;
  String? _selectedGnDivision;
  bool _isLoading = false;

  final List<String> _roles = [
    'farmer',
    'owner',
    'both'
  ];

  final List<String> _gnDivisions = [
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

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedGnDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Role and a GN Division')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final success = await authService.registerProfile(
        fullName: _fullNameController.text.trim(),
        role: _selectedRole!,
        gnDivision: _selectedGnDivision!,
      );

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully! Welcome.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile registration failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Force them to register profile to proceed
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.account_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 24),
                    const Text(
                      'Complete Your Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in your details to finalize registration on the platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Role Selector Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Your Role *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings),
                      ),
                      value: _selectedRole,
                      items: _roles.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r == 'both' ? 'Both (Farmer & Owner)' : r.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val),
                      validator: (val) => val == null ? 'Role is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // GN Division Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Home GN Division *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      value: _selectedGnDivision,
                      items: _gnDivisions.map((div) {
                        return DropdownMenuItem(
                          value: div,
                          child: Text(div),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGnDivision = val),
                      validator: (val) => val == null ? 'GN Division is required' : null,
                    ),
                    const SizedBox(height: 32),

                    // Register profile button
                    ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Profile & Finish', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
