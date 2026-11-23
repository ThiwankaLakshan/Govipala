import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';

class ReasonDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  const ReasonDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'තහවුරු කරන්න (Confirm)',
    this.isDestructive = true,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'තහවුරු කරන්න (Confirm)',
    bool isDestructive = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ReasonDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_reasonController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoviSpacing.radiusMd),
      ),
      title: Row(
        children: [
          Icon(
            widget.isDestructive ? Icons.warning_amber_rounded : Icons.info_outline,
            color: widget.isDestructive ? GoviColors.error : GoviColors.primary,
          ),
          const SizedBox(width: GoviSpacing.sm),
          Expanded(
            child: Text(
              widget.title,
              style: GoviTextStyles.heading2,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: GoviTextStyles.bodyText,
            ),
            const SizedBox(height: GoviSpacing.md),
            Text(
              'ක්‍රියාමාර්ගයට හේතුව (Mandatory Reason):',
              style: GoviTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: GoviColors.textPrimary,
              ),
            ),
            const SizedBox(height: GoviSpacing.xs),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'හේතුව මෙහි සටහන් කරන්න... (Enter reason for audit log)',
              ),
              validator: (val) {
                if (val == null || val.trim().length < 3) {
                  return 'කරුණාකර අවම වශයෙන් අකුරු 3 ක හේතුවක් ඇතුළත් කරන්න.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('අවලංගු කරන්න (Cancel)'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDestructive ? GoviColors.error : GoviColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
