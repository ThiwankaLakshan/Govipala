import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../models/audit_log.dart';
import '../../services/admin_api_service.dart';
import '../../widgets/empty_state.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<AuditLogItem> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await AdminApiService.fetchAuditLogs(targetTable: _selectedTable);
      if (mounted) {
        setState(() {
          _logs = logs;
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

  Color _actionColor(String action) {
    if (action.contains('CREATE')) return GoviColors.success;
    if (action.contains('UPDATE_STATUS') || action.contains('DEACTIVATE')) return GoviColors.warning;
    if (action.contains('DELETE')) return GoviColors.error;
    return GoviColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GoviSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('විගණන සටහන් (Admin Audit Log)', style: GoviTextStyles.heading1),
                  const SizedBox(height: GoviSpacing.xxs),
                  Text(
                    'පරිපාලකවරුන් විසින් සිදුකළ සියලුම වෙනස්කම් (Read-Only Log)',
                    style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'නැවුම් කරන්න',
                icon: const Icon(Icons.refresh, color: GoviColors.primary),
                onPressed: _loadAuditLogs,
              ),
            ],
          ),
          const SizedBox(height: GoviSpacing.md),

          // Filter by target table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('සියලුම සටහන් (All Tables)'),
                  selected: _selectedTable == null,
                  onSelected: (_) {
                    setState(() => _selectedTable = null);
                    _loadAuditLogs();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('පරිශීලක වෙනස්කම් (Users)'),
                  selected: _selectedTable == 'users',
                  onSelected: (val) {
                    setState(() => _selectedTable = val ? 'users' : null);
                    _loadAuditLogs();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('යන්ත්‍ර වෙනස්කම් (Machines)'),
                  selected: _selectedTable == 'machines',
                  onSelected: (val) {
                    setState(() => _selectedTable = val ? 'machines' : null);
                    _loadAuditLogs();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('වෙන්කිරීම් (Bookings)'),
                  selected: _selectedTable == 'bookings',
                  onSelected: (val) {
                    setState(() => _selectedTable = val ? 'bookings' : null);
                    _loadAuditLogs();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: GoviSpacing.md),

          // Audit log list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: GoviTextStyles.caption))
                    : _logs.isEmpty
                        ? const EmptyState(
                            icon: Icons.history,
                            title: 'විගණන සටහන් නොමැත',
                            subtitle: 'තෝරාගත් කාණ්ඩයට අදාළ වෙනස්කම් සටහන් වී නැත.',
                          )
                        : ListView.separated(
                            itemCount: _logs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: GoviSpacing.sm),
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final actColor = _actionColor(log.action);

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                  side: BorderSide(color: GoviColors.divider),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: GoviSpacing.md,
                                    vertical: GoviSpacing.xs,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: actColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      log.action,
                                      style: GoviTextStyles.caption.copyWith(
                                        color: actColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'වගුව: ${log.targetTable} • ඉලක්කය: ${log.targetId?.substring(0, 8) ?? "N/A"}...',
                                    style: GoviTextStyles.heading2.copyWith(fontSize: 15),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: GoviSpacing.xxs),
                                      Text(
                                        'පරිපාලක: ${log.adminName} • දිනය: ${log.createdAt.toLocal().toString().split(".")[0]}',
                                        style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                                      ),
                                      if (log.reason != null && log.reason!.isNotEmpty) ...[
                                        const SizedBox(height: GoviSpacing.xxs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                          ),
                                          child: Text(
                                            'හේතුව: ${log.reason}',
                                            style: GoviTextStyles.caption.copyWith(
                                              color: Colors.brown.shade800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(GoviSpacing.md),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (log.beforeData != null) ...[
                                            Text('වෙනස් කිරීමට පෙර (Before):', style: GoviTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                const JsonEncoder.withIndent('  ').convert(log.beforeData),
                                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(height: GoviSpacing.sm),
                                          ],
                                          if (log.afterData != null) ...[
                                            Text('වෙනස් කළ පසු (After):', style: GoviTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                const JsonEncoder.withIndent('  ').convert(log.afterData),
                                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
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
