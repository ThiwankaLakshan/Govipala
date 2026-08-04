import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _phoneNumber = '';
  String _role = '';
  String? _gnDivision;
  String _preferredLang = 'en';

  bool _isLoading = false;
  bool _isSaving = false;

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
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.get('/users/me');
      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _phoneNumber = profile['phone_number'] ?? '';
          _role = profile['role'] ?? '';
          _gnDivision = profile['gn_division'];
          _preferredLang = profile['preferred_lang'] ?? 'en';
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _gnDivision == null) return;

    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService.authToken);

    try {
      final response = await apiService.patch('/users/me', {
        'full_name': _nameController.text.trim(),
        'gn_division': _gnDivision,
        'preferred_lang': _preferredLang,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    
                    // Display non-editable variables
                    Text(
                      'Phone: $_phoneNumber',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Role: ${_role.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                    const SizedBox(height: 32),

                    // Full Name Form Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // GN Division dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'GN Division',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      value: _gnDivision,
                      items: _gnDivisions.map((div) {
                        return DropdownMenuItem(
                          value: div,
                          child: Text(div),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _gnDivision = val),
                    ),
                    const SizedBox(height: 20),

                    // Language toggles
                    const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('English'),
                            value: 'en',
                            groupValue: _preferredLang,
                            onChanged: (val) => setState(() => _preferredLang = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Sinhala'),
                            value: 'si',
                            groupValue: _preferredLang,
                            onChanged: (val) => setState(() => _preferredLang = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save and logout buttons
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
