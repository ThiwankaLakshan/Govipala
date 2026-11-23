import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../models/machine.dart';
import '../../services/admin_api_service.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import 'widgets/reason_dialog.dart';

class AdminMachinesScreen extends StatefulWidget {
  const AdminMachinesScreen({super.key});

  @override
  State<AdminMachinesScreen> createState() => _AdminMachinesScreenState();
}

class _AdminMachinesScreenState extends State<AdminMachinesScreen> {
  List<MachineModel> _machines = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedMachineType;
  bool? _selectedActiveFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMachines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final machines = await AdminApiService.fetchMachines(
        machineType: _selectedMachineType,
        isActive: _selectedActiveFilter,
        query: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _machines = machines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deactivateMachine(MachineModel machine) async {
    final reason = await ReasonDialog.show(
      context,
      title: 'යන්ත්‍රය අක්‍රීය කිරීම (Deactivate Machine)',
      message: 'ඔබ "${machine.brand} ${machine.modelName ?? ''}" යන්ත්‍රය හිමිකරු වෙනුවෙන් අක්‍රීය කිරීමට සූදානම් වේ. මෙය විගණන ලේඛනයේ සටහන් වේ.',
      confirmLabel: 'අක්‍රීය කරන්න (Deactivate)',
      isDestructive: true,
    );

    if (reason == null) return;

    try {
      await AdminApiService.deactivateMachine(machine.id, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${machine.brand} යන්ත්‍රය සාර්ථකව අක්‍රීය කරන ලදී.'),
            backgroundColor: GoviColors.success,
          ),
        );
        _loadMachines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('දෝෂය: ${e.toString()}'),
            backgroundColor: GoviColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GoviSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('යන්ත්‍ර කළමනාකරණය (Machine Management)', style: GoviTextStyles.heading1),
          const SizedBox(height: GoviSpacing.md),

          // Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'වර්ගය, මාදිලිය (Brand/Model) හෝ හිමිකරු නමින් සොයන්න...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadMachines();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadMachines(),
                ),
              ),
              const SizedBox(width: GoviSpacing.sm),
              IconButton(
                tooltip: 'සොයන්න (Search)',
                icon: const Icon(Icons.search, color: GoviColors.primary),
                onPressed: _loadMachines,
              ),
            ],
          ),
          const SizedBox(height: GoviSpacing.sm),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('සියල්ල (All)'),
                  selected: _selectedMachineType == null && _selectedActiveFilter == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedMachineType = null;
                      _selectedActiveFilter = null;
                    });
                    _loadMachines();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('හතරරෝද ට්‍රැක්ටර් (4-Wheel)'),
                  selected: _selectedMachineType == 'four_wheel_tractor',
                  onSelected: (val) {
                    setState(() => _selectedMachineType = val ? 'four_wheel_tractor' : null);
                    _loadMachines();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('අස්වනු නෙලන යන්ත්‍ර (Harvesters)'),
                  selected: _selectedMachineType == 'combine_harvester',
                  onSelected: (val) {
                    setState(() => _selectedMachineType = val ? 'combine_harvester' : null);
                    _loadMachines();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('දෙරෝද ට්‍රැක්ටර් (2-Wheel)'),
                  selected: _selectedMachineType == 'two_wheel_tractor',
                  onSelected: (val) {
                    setState(() => _selectedMachineType = val ? 'two_wheel_tractor' : null);
                    _loadMachines();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('වතුර මෝටර් (Water Pumps)'),
                  selected: _selectedMachineType == 'water_pump',
                  onSelected: (val) {
                    setState(() => _selectedMachineType = val ? 'water_pump' : null);
                    _loadMachines();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('අක්‍රීය (Inactive)'),
                  selected: _selectedActiveFilter == false,
                  onSelected: (val) {
                    setState(() => _selectedActiveFilter = val ? false : null);
                    _loadMachines();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: GoviSpacing.md),

          // Machine list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: GoviTextStyles.caption))
                    : _machines.isEmpty
                        ? const EmptyState(
                            icon: Icons.no_crash_outlined,
                            title: 'යන්ත්‍ර හමු නොවීය',
                            subtitle: 'තෝරාගත් පෙරහන් වලට අදාළ යන්ත්‍ර කිසිවක් නොමැත.',
                          )
                        : ListView.separated(
                            itemCount: _machines.length,
                            separatorBuilder: (_, __) => const SizedBox(height: GoviSpacing.xs),
                            itemBuilder: (context, index) {
                              final machine = _machines[index];

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                  side: BorderSide(
                                    color: machine.isActive ? GoviColors.divider : GoviColors.error.withOpacity(0.4),
                                  ),
                                ),
                                color: machine.isActive ? GoviColors.surface : GoviColors.error.withOpacity(0.03),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GoviSpacing.md,
                                    vertical: GoviSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: GoviColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                        ),
                                        child: Center(
                                          child: Text(
                                            machine.machineType == MachineType.combineHarvester
                                                ? '🌾'
                                                : (machine.machineType == MachineType.waterPump ? '💧' : '🚜'),
                                            style: const TextStyle(fontSize: 26),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: GoviSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${machine.brand} ${machine.modelName ?? ''}',
                                                    style: GoviTextStyles.heading2.copyWith(fontSize: 16),
                                                  ),
                                                ),
                                                if (machine.driveType != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: GoviColors.accent.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                                    ),
                                                    child: Text(
                                                      machine.driveType!.value.toUpperCase(),
                                                      style: GoviTextStyles.caption.copyWith(
                                                        color: GoviColors.accentDark,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: GoviSpacing.xs),
                                                ],
                                                StatusChip(status: machine.isActive ? 'active' : 'inactive'),
                                              ],
                                            ),
                                            const SizedBox(height: GoviSpacing.xxs),
                                            Text(
                                              '${machine.formattedRate} • වර්ගය: ${machine.machineType.sinhalaLabel}',
                                              style: GoviTextStyles.caption.copyWith(
                                                color: GoviColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: GoviSpacing.xxs),
                                            Text(
                                              'හිමිකරු: ${machine.ownerName ?? "N/A"} (${machine.ownerPhone ?? ""}) • වසම්: ${machine.serviceGnDivisions.join(", ")}',
                                              style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: GoviSpacing.md),
                                      if (machine.isActive)
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: GoviColors.error,
                                            side: const BorderSide(color: GoviColors.error),
                                          ),
                                          icon: const Icon(Icons.pause_circle_outline, size: 16),
                                          label: const Text('අක්‍රීය කරන්න (Deactivate)'),
                                          onPressed: () => _deactivateMachine(machine),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
