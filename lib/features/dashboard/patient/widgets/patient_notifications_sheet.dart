import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/neumorphic_card.dart';

class PatientNotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final String category;
  bool isRead;

  PatientNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.category,
    this.isRead = false,
  });
}

/// Responsive notifications panel / sheet for Patient Dashboard (Zero generic icons).
class PatientNotificationsSheet extends StatefulWidget {
  final VoidCallback? onClearUnread;

  const PatientNotificationsSheet({
    super.key,
    this.onClearUnread,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onClearUnread}) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PatientNotificationsSheet(onClearUnread: onClearUnread),
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: PatientNotificationsSheet(onClearUnread: onClearUnread),
          ),
        ),
      );
    }
  }

  @override
  State<PatientNotificationsSheet> createState() => _PatientNotificationsSheetState();
}

class _PatientNotificationsSheetState extends State<PatientNotificationsSheet> {
  final List<PatientNotificationItem> _notifications = [
    PatientNotificationItem(
      id: "1",
      title: "System Connected",
      message: "Connected to Clinova cloud healthcare database services.",
      timeAgo: "Just now",
      category: "SYSTEM",
      isRead: false,
    ),
    PatientNotificationItem(
      id: "2",
      title: "Case Summary Ready",
      message: "Your structured summary for 'Persistent Cough & Low Fever' is prepared for consultation.",
      timeAgo: "2 hours ago",
      category: "CASE",
      isRead: false,
    ),
    PatientNotificationItem(
      id: "3",
      title: "Doctor Review Feedback",
      message: "Dr. Marcus reviewed your previous clinical summary for 'Right Knee Strain'.",
      timeAgo: "2 days ago",
      category: "DOCTOR",
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    widget.onClearUnread?.call();
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    widget.onClearUnread?.call();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      color: ClinovaColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for mobile
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ClinovaColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          "Notifications",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ClinovaColors.primaryText,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: ClinovaColors.primaryAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$unreadCount new",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_notifications.isNotEmpty) ...[
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      "Mark read",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ClinovaColors.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      "Clear",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ClinovaColors.secondaryText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                // Text button for Close (no icon)
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ClinovaColors.surfaceNeumorphic,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ClinovaColors.borderLight, width: 0.8),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClinovaColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ClinovaColors.borderLight),

          // Content
          Flexible(
            child: _notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "ALL CAUGHT UP",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: ClinovaColors.primaryAccent,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No notifications yet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ClinovaColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "You're all caught up! New clinical updates and case review notices will appear here.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: ClinovaColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = _notifications[i];
                      return NeumorphicCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 14,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? const Color(0xFFE4ECE6)
                                    : const Color(0xFFDCECE2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: item.isRead
                                      ? ClinovaColors.secondaryText
                                      : ClinovaColors.primaryAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w700,
                                            color: ClinovaColors.primaryText,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: ClinovaColors.primaryAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.message,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: item.isRead
                                          ? ClinovaColors.secondaryText
                                          : ClinovaColors.primaryText.withValues(alpha: 0.85),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.timeAgo,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: ClinovaColors.secondaryText,
                                    ),
                                  ),
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
