import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';

class AddAvailabilityScreen extends StatefulWidget {
  final String? preselectedMachineId;

  const AddAvailabilityScreen({super.key, this.preselectedMachineId});

  @override
  State<AddAvailabilityScreen> createState() => _AddAvailabilityScreenState();
}

class _AddAvailabilityScreenState extends State<AddAvailabilityScreen> {
  List<MachineModel> _machines = [];
  String? _selectedMachineId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _morningSlot = true;
  bool _afternoonSlot = true;
  bool _repeatNext3Days = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    try {
      final list = await ApiService.fetchMachines();
      if (mounted) {
        setState(() {
          _machines = list;
          _selectedMachineId = widget.preselectedMachineId ?? (list.isNotEmpty ? list.first.id : null);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitSlots() async {
    if (_selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර යන්ත්‍රයක් තෝරන්න.'), backgroundColor: GoviColors.danger),
      );
      return;
    }

    if (!_morningSlot && !_afternoonSlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර අවම වශයෙන් එක් වේලා වාරයක් තෝරන්න.'), backgroundColor: GoviColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final daysCount = _repeatNext3Days ? 3 : 1;
      final List<Map<String, dynamic>> slotsToCreate = [];

      for (int i = 0; i < daysCount; i++) {
        final d = _selectedDate.add(Duration(days: i));
        final dateStr = d.toISOString().split('T')[0];

        if (_morningSlot) {
          slotsToCreate.add({
            'slot_date': dateStr,
            'start_time': '07:00:00',
            'end_time': '12:00:00',
          });
        }

        if (_afternoonSlot) {
          slotsToCreate.add({
            'slot_date': dateStr,
            'start_time': '13:00:00',
            'end_time': '17:00:00',
          });
        }
      }

      final count = await ApiService.createAvailabilitySlots(_selectedMachineId!, slotsToCreate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('සාර්ථකයි! වෙන්කිරීම් වාර $count ක් එක් කරන ලදී.'),
            backgroundColor: GoviColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('දෝෂය: ${e.toString()}'), backgroundColor: GoviColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('වේලාවන් එක් කරන්න (Add Slots)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(GoviSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('යන්ත්‍රය තෝරන්න (Select Machine)', style: GoviTextStyles.sectionTitle),
                  const SizedBox(height: GoviSpacing.xs),
                  DropdownButtonFormField<String>(
                    value: _selectedMachineId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.precision_manufacturing_rounded, color: GoviColors.primary),
                    ),
                    items: _machines.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.brand} ${m.modelName ?? ""} (${m.machineTypeSinhala})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMachineId = val),
                  ),

                  const SizedBox(height: GoviSpacing.lg),

                  const Text('දිනය (Date)', style: GoviTextStyles.sectionTitle),
                  const SizedBox(height: GoviSpacing.xs),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: GoviColors.surface,
                        borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
                        border: Border.all(color: GoviColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: GoviColors.primary),
                          const SizedBox(width: GoviSpacing.md),
                          Text(
                            _selectedDate.toISOString().split('T')[0],
                            style: GoviTextStyles.bodyBold,
                          ),
                          const Spacer(),
                          const Text('වෙනස් කරන්න (Change)', style: TextStyle(color: GoviColors.primary)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: GoviSpacing.lg),

                  const Text('වේලා වාර (Time Blocks)', style: GoviTextStyles.sectionTitle),
                  const SizedBox(height: GoviSpacing.xs),
                  CheckboxListTile(
                    title: const Text('උදෑසන වාරය (Morning)', style: GoviTextStyles.bodyBold),
                    subtitle: const Text('07:00 AM - 12:00 PM'),
                    activeColor: GoviColors.primary,
                    value: _morningSlot,
                    onChanged: (val) => setState(() => _morningSlot = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('සවස වාරය (Afternoon)', style: GoviTextStyles.bodyBold),
                    subtitle: const Text('01:00 PM - 05:00 PM'),
                    activeColor: GoviColors.primary,
                    value: _afternoonSlot,
                    onChanged: (val) => setState(() => _afternoonSlot = val ?? false),
                  ),

                  const SizedBox(height: GoviSpacing.md),

                  SwitchListTile(
                    title: const Text('මීළඟ දින 3 සඳහාම නැවත එක් කරන්න', style: GoviTextStyles.bodyBold),
                    subtitle: const Text('Repeat for next 3 consecutive days'),
                    activeColor: GoviColors.primary,
                    value: _repeatNext3Days,
                    onChanged: (val) => setState(() => _repeatNext3Days = val),
                  ),

                  const SizedBox(height: GoviSpacing.xl),

                  GoviButton(
                    label: _isSubmitting ? 'සුරකිමින්...' : 'වේලාවන් සුරකින්න (Publish Slots)',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submitSlots,
                  ),
                ],
              ),
            ),
    );
  }
}

extension on DateTime {
  String toISOString() => toIso8601String();
}
