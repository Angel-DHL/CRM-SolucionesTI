// lib/operatividad/widgets/notifications_panel.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_notification.dart';
import '../services/notification_service.dart';

class NotificationsPanel extends StatelessWidget {
  final VoidCallback? onNotificationTap;

  const NotificationsPanel({super.key, this.onNotificationTap});

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.activityAssigned:
        return AppColors.primary;
      case NotificationType.activityDueSoon:
        return AppColors.warning;
      case NotificationType.activityOverdue:
        return AppColors.error;
      case NotificationType.commentReceived:
        return AppColors.info;
      case NotificationType.statusChanged:
        return AppColors.primaryLight;
      case NotificationType.slaWarning:
        return AppColors.warning;
      case NotificationType.slaBreached:
        return AppColors.error;
      case NotificationType.workCompleted:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.activityAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationType.activityDueSoon:
        return Icons.timer_rounded;
      case NotificationType.activityOverdue:
        return Icons.warning_amber_rounded;
      case NotificationType.commentReceived:
        return Icons.chat_bubble_rounded;
      case NotificationType.statusChanged:
        return Icons.sync_rounded;
      case NotificationType.slaWarning:
        return Icons.speed_rounded;
      case NotificationType.slaBreached:
        return Icons.cancel_rounded;
      case NotificationType.workCompleted:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),

          // Notifications list
          Flexible(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: NotificationService.streamNotifications(limit: 30),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppDimensions.xl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                final notifications = docs
                    .map(OperNotification.fromDoc)
                    .toList();

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.sm,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationItem(
                      notification: notification,
                      color: _getTypeColor(notification.type),
                      icon: _getTypeIcon(notification.type),
                      onTap: () {
                        NotificationService.markAsRead(notification.id);
                        onNotificationTap?.call();
                      },
                      onDismiss: () {
                        NotificationService.deleteNotification(notification.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Notificaciones',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StreamBuilder<int>(
            stream: NotificationService.streamUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: () => NotificationService.markAllAsRead(),
                child: Text(
                  'Leer todas ($count)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 48,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Sin notificaciones',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Aquí aparecerán tus alertas',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final OperNotification notification;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.lg),
        color: AppColors.error.withOpacity(0.1),
        child: Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : color.withOpacity(0.05),
            border: Border(
              left: notification.isRead
                  ? BorderSide.none
                  : BorderSide(color: color, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppDimensions.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      notification.timeAgo,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de notificaciones para el AppBar
class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.streamUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            child: Icon(
              count > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: count > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          tooltip: 'Notificaciones',
        );
      },
    );
  }
}
