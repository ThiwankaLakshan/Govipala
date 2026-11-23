import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../models/user.dart';
import '../../services/admin_api_service.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import 'widgets/reason_dialog.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedRole;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await AdminApiService.fetchUsers(
        role: _selectedRole,
        status: _selectedStatus,
        query: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _users = users;
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

  Future<void> _toggleUserStatus(UserModel user) async {
    final newStatus = user.status == 'active' ? 'suspended' : 'active';
    final actionName = newStatus == 'suspended' ? 'අත්හිටුවීම (Suspend)' : 'නැවත සක්‍රීය කිරීම (Activate)';

    final reason = await ReasonDialog.show(
      context,
      title: '$actionName - ${user.fullName}',
      message: 'ඔබ මෙම පරිශීලකයාගේ තත්ත්වය "$newStatus" ලෙස වෙනස් කිරීමට සූදානම් වේ. මෙය විගණන ලේඛනයේ සටහන් වේ.',
      confirmLabel: newStatus == 'suspended' ? 'අත්හිටුවන්න (Suspend)' : 'සක්‍රීය කරන්න (Activate)',
      isDestructive: newStatus == 'suspended',
    );

    if (reason == null) return;

    try {
      await AdminApiService.updateUserStatus(
        user.id,
        status: newStatus,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} ගේ තත්ත්වය සාර්ථකව යාවත්කාලීන විය.'),
            backgroundColor: GoviColors.success,
          ),
        );
        _loadUsers();
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

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gnCtrl = TextEditingController(text: 'Padaviya Town');
    final reasonCtrl = TextEditingController();
    String selectedRole = 'farmer';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GoviSpacing.radiusMd)),
          title: Text('නව පරිශීලකයෙකු ලියාපදිංචි කිරීම (Add User)', style: GoviTextStyles.heading2),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'සම්පූර්ණ නම (Full Name) *'),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'වලංගු නමක් ඇතුළත් කරන්න' : null,
                  ),
                  const SizedBox(height: GoviSpacing.sm),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'දුරකථන අංකය (Phone Number) *', hintText: '+947XXXXXXXX'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'දුරකථන අංකය ඇතුළත් කරන්න' : null,
                  ),
                  const SizedBox(height: GoviSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'භූමිකාව (Role) *'),
                    items: const [
                      DropdownMenuItem(value: 'farmer', child: Text('ගොවි මහතා (Farmer)')),
                      DropdownMenuItem(value: 'owner', child: Text('යන්ත්‍ර හිමිකරු (Machine Owner)')),
                      DropdownMenuItem(value: 'both', child: Text('දෙපාර්ශවයම (Both)')),
                      DropdownMenuItem(value: 'admin', child: Text('පරිපාලක (Admin)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: GoviSpacing.sm),
                  TextFormField(
                    controller: gnCtrl,
                    decoration: const InputDecoration(labelText: 'ග්‍රාම නිලධාරී වසම (GN Division)'),
                  ),
                  const SizedBox(height: GoviSpacing.sm),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'ඇතුළත් කිරීමට හේතුව (Reason for Audit Log)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('අවලංගු කරන්න'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  try {
                    await AdminApiService.createUser(
                      fullName: nameCtrl.text.trim(),
                      role: selectedRole,
                      phoneNumber: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                      gnDivision: gnCtrl.text.trim(),
                      reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Created by Admin',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('පරිශීලකයා සාර්ථකව එක් කරන ලදී.'), backgroundColor: GoviColors.success),
                      );
                      _loadUsers();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('දෝෂය: ${e.toString()}'), backgroundColor: GoviColors.error),
                      );
                    }
                  }
                }
              },
              child: const Text('එක් කරන්න (Add)'),
            ),
          ],
        ),
      ),
    );
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
              Text('පරිශීලක කළමනාකරණය (User Management)', style: GoviTextStyles.heading1),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('නව පරිශීලක (Add User)'),
                onPressed: _showAddUserDialog,
              ),
            ],
          ),
          const SizedBox(height: GoviSpacing.md),

          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'නම, දුරකථන අංකය හෝ විද්‍යුත් තැපෑල මඟින් සොයන්න...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: GoviSpacing.sm),
              IconButton(
                tooltip: 'සොයන්න (Search)',
                icon: const Icon(Icons.search, color: GoviColors.primary),
                onPressed: _loadUsers,
              ),
            ],
          ),
          const SizedBox(height: GoviSpacing.sm),

          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('සියල්ල (All)'),
                  selected: _selectedRole == null && _selectedStatus == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedRole = null;
                      _selectedStatus = null;
                    });
                    _loadUsers();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('ගොවීන් (Farmers)'),
                  selected: _selectedRole == 'farmer',
                  onSelected: (val) {
                    setState(() => _selectedRole = val ? 'farmer' : null);
                    _loadUsers();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('හිමිකරුවන් (Owners)'),
                  selected: _selectedRole == 'owner',
                  onSelected: (val) {
                    setState(() => _selectedRole = val ? 'owner' : null);
                    _loadUsers();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('දෙපාර්ශවයම (Both)'),
                  selected: _selectedRole == 'both',
                  onSelected: (val) {
                    setState(() => _selectedRole = val ? 'both' : null);
                    _loadUsers();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('පරිපාලක (Admins)'),
                  selected: _selectedRole == 'admin',
                  onSelected: (val) {
                    setState(() => _selectedRole = val ? 'admin' : null);
                    _loadUsers();
                  },
                ),
                const SizedBox(width: GoviSpacing.xs),
                FilterChip(
                  label: const Text('අත්හිටවූ (Suspended)'),
                  selected: _selectedStatus == 'suspended',
                  onSelected: (val) {
                    setState(() => _selectedStatus = val ? 'suspended' : null);
                    _loadUsers();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: GoviSpacing.md),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: GoviTextStyles.caption))
                    : _users.isEmpty
                        ? const EmptyState(
                            icon: Icons.person_off_outlined,
                            title: 'පරිශීලකයින් හමු නොවීය',
                            subtitle: 'තෝරාගත් පෙරහන් වලට අදාළ පරිශීලකයින් නැත.',
                          )
                        : ListView.separated(
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: GoviSpacing.xs),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final isSuspended = user.status == 'suspended';

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                  side: BorderSide(
                                    color: isSuspended ? GoviColors.error.withOpacity(0.5) : GoviColors.divider,
                                  ),
                                ),
                                color: isSuspended ? GoviColors.error.withOpacity(0.04) : GoviColors.surface,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GoviSpacing.md,
                                    vertical: GoviSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSuspended
                                            ? GoviColors.error.withOpacity(0.15)
                                            : GoviColors.primary.withOpacity(0.12),
                                        child: Icon(
                                          user.role == 'owner'
                                              ? Icons.precision_manufacturing
                                              : (user.role == 'admin' ? Icons.admin_panel_settings : Icons.person),
                                          color: isSuspended ? GoviColors.error : GoviColors.primary,
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
                                                    user.fullName,
                                                    style: GoviTextStyles.heading2.copyWith(fontSize: 16),
                                                  ),
                                                ),
                                                StatusChip(status: user.role.name),
                                                const SizedBox(width: GoviSpacing.xs),
                                                StatusChip(status: user.status),
                                              ],
                                            ),
                                            const SizedBox(height: GoviSpacing.xxs),
                                            Text(
                                              '${user.phoneNumber ?? user.email ?? "No contact"} • වසම: ${user.gnDivision ?? "Not set"}',
                                              style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: GoviSpacing.md),
                                      if (user.role != 'admin')
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isSuspended ? GoviColors.success : GoviColors.error,
                                            side: BorderSide(
                                              color: isSuspended ? GoviColors.success : GoviColors.error,
                                            ),
                                          ),
                                          icon: Icon(
                                            isSuspended ? Icons.check_circle_outline : Icons.block,
                                            size: 16,
                                          ),
                                          label: Text(isSuspended ? 'සක්‍රීය කරන්න' : 'අත්හිටුවන්න'),
                                          onPressed: () => _toggleUserStatus(user),
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
