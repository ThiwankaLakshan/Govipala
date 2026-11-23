import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/machine_card.dart';
import '../../widgets/empty_state.dart';
import 'machine_detail_screen.dart';

class BrowseMachinesScreen extends StatefulWidget {
  final MachineType? initialType;
  final String? initialGnDivision;

  const BrowseMachinesScreen({
    super.key,
    this.initialType,
    this.initialGnDivision,
  });

  @override
  State<BrowseMachinesScreen> createState() => _BrowseMachinesScreenState();
}

class _BrowseMachinesScreenState extends State<BrowseMachinesScreen> {
  MachineType? _selectedType;
  String? _selectedGnDivision;
  List<String> _gnDivisions = [];
  List<MachineModel> _machines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedGnDivision = widget.initialGnDivision;
    _initFiltersAndLoad();
  }

  Future<void> _initFiltersAndLoad() async {
    final divisions = await ApiService.asyncFetchGnDivisions();
    if (mounted) {
      setState(() {
        _gnDivisions = divisions;
      });
    }
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.fetchMachines(
        machineType: _selectedType,
        gnDivision: _selectedGnDivision,
        isActive: true,
      );
      await OfflineCacheService.cacheMachines(list);
      if (mounted) {
        setState(() {
          _machines = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      final cached = await OfflineCacheService.getCachedMachines();
      if (mounted) {
        setState(() {
          _machines = cached;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('යන්ත්‍ර සොයන්න (Find Machines)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GoviSpacing.screenPadding,
                vertical: GoviSpacing.sm,
              ),
              color: GoviColors.surface,
              child: Column(
                children: [
                  // Machine Type Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedType == null,
                          label: const Text('සියල්ල (All)'),
                          selectedColor: GoviColors.primarySoft,
                          checkmarkColor: GoviColors.primary,
                          labelStyle: GoviTextStyles.caption.copyWith(
                            color: _selectedType == null ? GoviColors.primaryDark : GoviColors.textPrimary,
                            fontWeight: _selectedType == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedType = null);
                            _loadMachines();
                          },
                        ),
                        ...MachineType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(left: GoviSpacing.xs),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(type.sinhalaLabel),
                              selectedColor: GoviColors.primarySoft,
                              checkmarkColor: GoviColors.primary,
                              labelStyle: GoviTextStyles.caption.copyWith(
                                color: isSelected ? GoviColors.primaryDark : GoviColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedType = isSelected ? null : type);
                                _loadMachines();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: GoviSpacing.xs),
                  // GN Division filter dropdown
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18.0, color: GoviColors.primary),
                      const SizedBox(width: GoviSpacing.xs),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _selectedGnDivision,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          hint: const Text('සියලුම පදවිය වසම් (All GN Divisions)', style: GoviTextStyles.caption),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('සියලුම පදවිය වසම් (All Padaviya)', style: GoviTextStyles.body),
                            ),
                            ..._gnDivisions.map((d) => DropdownMenuItem<String?>(
                                  value: d,
                                  child: Text(d, style: GoviTextStyles.body),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedGnDivision = val);
                            _loadMachines();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1.0, color: GoviColors.border),

            // Machines List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: GoviColors.primary),
                    )
                  : _machines.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'යන්ත්‍ර හමුනොවීය',
                          subtitle: 'තෝරාගත් වර්ගයට හෝ ප්‍රදේශයට ගැළපෙන යන්ත්‍ර කිසිවක් මෙම අවස්ථාවේ නොමැත.',
                          actionLabel: 'පෙරහන් ඉවත් කරන්න (Clear Filters)',
                          onAction: () {
                            setState(() {
                              _selectedType = null;
                              _selectedGnDivision = null;
                            });
                            _loadMachines();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMachines,
                          color: GoviColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(GoviSpacing.screenPadding),
                            itemCount: _machines.length,
                            itemBuilder: (ctx, idx) {
                              final machine = _machines[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: GoviSpacing.md),
                                child: MachineCard(
                                  machine: machine,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MachineDetailScreen(machineId: machine.id),
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
      ),
    );
  }
}
