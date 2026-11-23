import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/govi_card.dart';

class AddEditMachineScreen extends StatefulWidget {
  final MachineModel? machineToEdit;

  const AddEditMachineScreen({super.key, this.machineToEdit});

  @override
  State<AddEditMachineScreen> createState() => _AddEditMachineScreenState();
}

class _AddEditMachineScreenState extends State<AddEditMachineScreen> {
  late MachineType _selectedType;
  late TextEditingController _brandController;
  DriveType? _selectedDriveType;
  late TextEditingController _modelController;
  late TextEditingController _rateController;
  late RateUnit _selectedRateUnit;
  late TextEditingController _photoUrlController;
  List<String> _availableGnDivisions = [];
  final Set<String> _selectedGnDivisions = {};

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final m = widget.machineToEdit;
    _selectedType = m?.machineType ?? MachineType.fourWheelTractor;
    _brandController = TextEditingController(text: m?.brand ?? '');
    _selectedDriveType = m?.driveType ?? (_selectedType == MachineType.fourWheelTractor ? DriveType.fourWheel : null);
    _modelController = TextEditingController(text: m?.modelName ?? '');
    _rateController = TextEditingController(text: m != null ? m.rateAmount.toStringAsFixed(0) : '');
    _selectedRateUnit = m?.rateUnit ?? RateUnit.hour;
    _photoUrlController = TextEditingController(text: m?.photoUrl ?? '');

    if (m != null) {
      _selectedGnDivisions.addAll(m.serviceGnDivisions);
    }

    _loadGnDivisions();
  }

  Future<void> _loadGnDivisions() async {
    final list = await ApiService.asyncFetchGnDivisions();
    if (mounted) {
      setState(() {
        _availableGnDivisions = list;
        if (widget.machineToEdit == null && _selectedGnDivisions.isEmpty && list.isNotEmpty) {
          _selectedGnDivisions.add(list.first);
        }
      });
    }
  }

  Future<void> _saveMachine() async {
    final brand = _brandController.text.trim();
    if (brand.isEmpty) {
      setState(() => _errorMessage = 'යන්ත්‍රයේ වෙළඳනාමය (Brand) ඇතුළත් කරන්න.');
      return;
    }

    if (_selectedType == MachineType.fourWheelTractor && _selectedDriveType == null) {
      setState(() => _errorMessage = 'හතර රෝද ට්‍රැක්ටර් සඳහා ධාවන මාදිලිය (2WD හෝ 4WD) තෝරන්න.');
      return;
    }

    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate <= 0) {
      setState(() => _errorMessage = 'වලංගු අයකිරීමේ මුදලක් ඇතුළත් කරන්න.');
      return;
    }

    if (_selectedGnDivisions.isEmpty) {
      setState(() => _errorMessage = 'අවම වශයෙන් එක් සේවා වසමක් (GN Division) තෝරන්න.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.machineToEdit == null) {
        // Create new
        await ApiService.createMachine(
          machineType: _selectedType,
          brand: brand,
          driveType: _selectedType == MachineType.fourWheelTractor ? _selectedDriveType : null,
          modelName: _modelController.text.trim(),
          rateAmount: rate,
          rateUnit: _selectedRateUnit,
          photoUrl: _photoUrlController.text.trim(),
          serviceGnDivisions: _selectedGnDivisions.toList(),
        );
      } else {
        // Update existing
        await ApiService.updateMachine(
          id: widget.machineToEdit!.id,
          machineType: _selectedType,
          brand: brand,
          driveType: _selectedType == MachineType.fourWheelTractor ? _selectedDriveType : null,
          modelName: _modelController.text.trim(),
          rateAmount: rate,
          rateUnit: _selectedRateUnit,
          photoUrl: _photoUrlController.text.trim(),
          serviceGnDivisions: _selectedGnDivisions.toList(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // Return success
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.machineToEdit != null;

    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'යන්ත්‍රය සංස්කරණය (Edit)' : 'නව යන්ත්‍රයක් එක්කරන්න (Add Machine)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GoviSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Machine Type (4 big tiles)
              const Text('1. යන්ත්‍ර වර්ගය (Machine Type):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              _buildMachineTypeGrid(),
              const SizedBox(height: GoviSpacing.lg),

              // 2. Brand (text field typed by owner)
              const Text('2. වෙළඳ නාමය (Brand):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  hintText: 'උදා: Massey Ferguson, Kubota, John Deere, Tafe',
                  prefixIcon: Icon(Icons.branding_watermark_outlined),
                ),
              ),
              const SizedBox(height: GoviSpacing.lg),

              // 3. Drive Type dropdown (2WD / 4WD) - ONLY FOR FOUR-WHEEL TRACTOR
              if (_selectedType == MachineType.fourWheelTractor) ...[
                const Text('3. ධාවන මාදිලිය (Drive Type - 2WD/4WD):', style: GoviTextStyles.bodyBold),
                const SizedBox(height: GoviSpacing.xs),
                DropdownButtonFormField<DriveType>(
                  value: _selectedDriveType ?? DriveType.fourWheel,
                  items: DriveType.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d.label, style: GoviTextStyles.body),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDriveType = val),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.settings_outlined),
                  ),
                ),
                const SizedBox(height: GoviSpacing.lg),
              ],

              // 4. Model Name (optional)
              const Text('4. මෝඩලය (Model Name - Optional):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  hintText: 'උදා: 240, 5050D, L4508',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: GoviSpacing.lg),

              // 5. Rate + Unit (segmented control)
              const Text('5. කුලී අයකිරීම (Rental Rate):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '3500',
                        prefixText: 'රු. ',
                      ),
                    ),
                  ),
                  const SizedBox(width: GoviSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<RateUnit>(
                      value: _selectedRateUnit,
                      items: RateUnit.values.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text(u.label, style: GoviTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRateUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GoviSpacing.lg),

              // 6. GN Divisions Served (Multi-select chips)
              const Text('6. සේවා සපයන පදවිය වසම් (GN Divisions):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              Wrap(
                spacing: GoviSpacing.xs,
                runSpacing: GoviSpacing.xs,
                children: _availableGnDivisions.map((division) {
                  final isSelected = _selectedGnDivisions.contains(division);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(division),
                    selectedColor: GoviColors.primarySoft,
                    checkmarkColor: GoviColors.primary,
                    labelStyle: GoviTextStyles.caption.copyWith(
                      color: isSelected ? GoviColors.primaryDark : GoviColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGnDivisions.add(division);
                        } else {
                          _selectedGnDivisions.remove(division);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Photo URL (optional)
              const Text('7. ඡායාරූප සබැඳිය (Photo URL - Optional):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              TextField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.photo_camera_outlined),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: GoviSpacing.md),
                Text(_errorMessage!, style: GoviTextStyles.caption.copyWith(color: GoviColors.danger)),
              ],

              const SizedBox(height: GoviSpacing.xl),
              GoviButton(
                label: isEditing ? 'වෙනස්කම් සුරකින්න (Save Changes)' : 'යන්ත්‍රය ඇතුළත් කරන්න (Publish)',
                icon: Icons.check_circle_rounded,
                isLoading: _isLoading,
                onPressed: _saveMachine,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: GoviSpacing.sm,
      crossAxisSpacing: GoviSpacing.sm,
      childAspectRatio: 2.2,
      children: MachineType.values.map((type) {
        final isSelected = _selectedType == type;
        return GoviCard(
          padding: const EdgeInsets.symmetric(horizontal: GoviSpacing.sm, vertical: GoviSpacing.xs),
          onTap: () {
            setState(() {
              _selectedType = type;
              if (type == MachineType.fourWheelTractor && _selectedDriveType == null) {
                _selectedDriveType = DriveType.fourWheel;
              } else if (type != MachineType.fourWheelTractor) {
                _selectedDriveType = null;
              }
            });
          },
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? GoviColors.primary : GoviColors.textSecondary,
                size: 20.0,
              ),
              const SizedBox(width: GoviSpacing.xs),
              Expanded(
                child: Text(
                  type.sinhalaLabel,
                  style: GoviTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? GoviColors.primaryDark : GoviColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
