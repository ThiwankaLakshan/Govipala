class AuditLogItem {
  final String id;
  final String adminId;
  final String adminName;
  final String action;
  final String targetTable;
  final String? targetId;
  final dynamic beforeData;
  final dynamic afterData;
  final String? reason;
  final DateTime createdAt;

  const AuditLogItem({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetTable,
    this.targetId,
    this.beforeData,
    this.afterData,
    this.reason,
    required this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id'] as String? ?? '',
      adminId: json['admin_id'] as String? ?? '',
      adminName: json['admin_name'] as String? ?? 'Admin',
      action: json['action'] as String? ?? '',
      targetTable: json['target_table'] as String? ?? '',
      targetId: json['target_id'] as String?,
      beforeData: json['before_data'],
      afterData: json['after_data'],
      reason: json['reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
