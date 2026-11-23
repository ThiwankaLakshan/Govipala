import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.fetchMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'දැනුම්දීම් ලබාගැනීමට නොහැකි විය (Failed to load notifications)';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('දැනුම්දීම් (Notifications)'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: GoviColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: GoviTextStyles.caption.copyWith(color: GoviColors.danger)),
                        const SizedBox(height: GoviSpacing.md),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('නැවත උත්සාහ කරන්න (Retry)'),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            EmptyState(
                              icon: Icons.notifications_none_rounded,
                              title: 'දැනුම්දීම් කිසිවක් නැත',
                              subtitle: 'No notifications yet',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(GoviSpacing.screenPadding),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: GoviSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            final isPush = item.isPush;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
                                side: const BorderSide(color: GoviColors.border, width: 1.0),
                              ),
                              color: GoviColors.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(GoviSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Channel icon badge
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isPush ? GoviColors.primarySoft : GoviColors.info.withAlpha(40),
                                        borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                      ),
                                      child: Icon(
                                        isPush ? Icons.notifications_active_rounded : Icons.sms_rounded,
                                        size: 20,
                                        color: isPush ? GoviColors.primary : GoviColors.info,
                                      ),
                                    ),
                                    const SizedBox(width: GoviSpacing.md),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title ?? (isPush ? 'Push Notification' : 'SMS Alert'),
                                                  style: GoviTextStyles.bodyBold.copyWith(fontSize: 14),
                                                ),
                                              ),
                                              Text(
                                                _formatTime(item.sentAt),
                                                style: GoviTextStyles.caption.copyWith(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.message,
                                            style: GoviTextStyles.caption.copyWith(
                                              color: GoviColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
