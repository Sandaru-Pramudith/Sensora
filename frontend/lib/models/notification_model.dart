import 'package:flutter/material.dart';

/// Maps a raw JSON notification from the FastAPI backend.
class NotificationModel {
  final int id;
  final String notificationType;
  final String title;
  final String message;
  final String severity;
  final int? relatedId;
  final bool isRead;
  final String? createdAt;
  final String? readAt;

  const NotificationModel({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.severity,
    this.relatedId,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: (j['id'] as num).toInt(),
      notificationType: j['notification_type'] as String? ?? 'system',
      title: j['title'] as String? ?? '',
      message: j['message'] as String? ?? '',
      severity: j['severity'] as String? ?? 'info',
      relatedId: j['related_id'] != null ? (j['related_id'] as num).toInt() : null,
      isRead: (j['is_read'] == true || j['is_read'] == 1),
      createdAt: j['created_at'] as String?,
      readAt: j['read_at'] as String?,
    );
  }

  /// Human-friendly time string from the ISO/MySQL datetime.
  String get timeAgo {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return createdAt ?? '';
    }
  }

  /// Tab category label shown in the filter bar.
  String get tabCategory {
    switch (notificationType) {
      case 'alert_triggered':
      case 'alert_acknowledged':
        return 'Alerts';
      case 'device_offline':
        return 'Devices';
      default:
        return 'System';
    }
  }

  /// Icon matching the notification type.
  IconData get icon {
    switch (notificationType) {
      case 'alert_triggered':
        return severity == 'critical'
            ? Icons.warning_amber_rounded
            : Icons.notifications_active_outlined;
      case 'alert_acknowledged':
        return Icons.check_circle_outline;
      case 'device_offline':
        return Icons.wifi_off_outlined;
      default:
        return Icons.info_outline;
    }
  }

  /// Colour matching severity.
  Color get severityColor {
    switch (severity) {
      case 'critical':
        return const Color(0xFFCB5B5B);
      case 'warning':
        return const Color(0xFFCBAF5B);
      default:
        return const Color(0xFF5B9ECB);
    }
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        notificationType: notificationType,
        title: title,
        message: message,
        severity: severity,
        relatedId: relatedId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        readAt: readAt,
      );
}
