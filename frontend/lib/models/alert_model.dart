import 'package:flutter/material.dart';

class AlertModel {
  final int id;
  final String batchId;
  final String fruitType;
  final String alertType;
  final String message;
  final String severity;
  final double value;
  final double threshold;
  final bool acknowledged;
  final String? acknowledgedBy;
  final String? acknowledgedAt;
  final String? createdAt;

  const AlertModel({
    required this.id,
    required this.batchId,
    required this.fruitType,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.value,
    required this.threshold,
    required this.acknowledged,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: (j['id'] as num).toInt(),
        batchId: j['batch_id'] as String? ?? '',
        fruitType: j['fruit_type'] as String? ?? '',
        alertType: j['alert_type'] as String? ?? '',
        message: j['message'] as String? ?? '',
        severity: j['severity'] as String? ?? 'critical',
        value: (j['value'] as num?)?.toDouble() ?? 0.0,
        threshold: (j['threshold'] as num?)?.toDouble() ?? 0.0,
        acknowledged: (j['acknowledged'] == true || j['acknowledged'] == 1),
        acknowledgedBy: j['acknowledged_by'] as String?,
        acknowledgedAt: j['acknowledged_at'] as String?,
        createdAt: j['created_at'] as String?,
      );

  String get timeAgo {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return createdAt ?? '';
    }
  }

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return const Color(0xFFCB5B5B);
      default:
        return const Color(0xFFCBAF5B);
    }
  }

  IconData get icon {
    switch (alertType.toLowerCase()) {
      case 'spoilage':
      case 'spoiled':
        return Icons.warning_amber_rounded;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'ethylene':
        return Icons.air;
      case 'voc':
      case 'tvoc':
        return Icons.science_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
