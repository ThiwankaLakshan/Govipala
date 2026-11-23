import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Offline banner shown when connection is absent or syncing (06_UI_UX_GUIDE.md Section 4)
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final bool isSyncing;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isSyncing) {
      return const SizedBox.shrink();
    }

    final bool syncing = isSyncing;
    final Color bgColor = syncing ? GoviColors.info : GoviColors.accent;
    final String message = syncing
        ? 'සම්බන්ධ වෙමින් පවතී... (Syncing)'
        : 'සම්බන්ධතාවය නැත: සුරකින ලද දත්ත පෙන්වයි (No connection)';

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: GoviSpacing.screenPadding, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            syncing ? Icons.sync_rounded : Icons.wifi_off_rounded,
            size: 16.0,
            color: Colors.white,
          ),
          const SizedBox(width: GoviSpacing.sm),
          Text(
            message,
            style: GoviTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
