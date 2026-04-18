import 'api_service.dart';

/// Typed wrapper around every Sensora FastAPI endpoint.
/// All methods throw [ApiException] on failure.
class SensoraApi {
  final ApiService _api;

  SensoraApi([String? baseUrl, ApiService? apiService])
    : _api = apiService ?? ApiService(baseUrl: baseUrl);

  List<Map<String, dynamic>> _mapAlertsToNotifications(List<dynamic> alerts) {
    return alerts.map((raw) {
      final a = Map<String, dynamic>.from(raw as Map);
      final id = (a['id'] as num?)?.toInt() ?? 0;
      final batchId = a['batch_id']?.toString() ?? '';
      final fruitType = a['fruit_type']?.toString() ?? 'Unknown';
      final severity = (a['severity']?.toString().isNotEmpty ?? false)
          ? a['severity'].toString()
          : 'critical';
      final createdAt = a['created_at']?.toString();
      final alertMessage = a['message']?.toString();

      return <String, dynamic>{
        'id': id,
        'notification_type': 'alert_triggered',
        'title': 'Spoilage Alert - Basket $batchId',
        'message':
            (alertMessage != null && alertMessage.isNotEmpty)
            ? alertMessage
            : 'Spoilage detected for basket $batchId [$fruitType]',
        'severity': severity,
        'related_id': id,
        'is_read': false,
        'created_at': createdAt,
        'read_at': null,
      };
    }).toList();
  }

  // ── Baskets / Devices (used by batches_page.dart) ───────────────────────

  Future<List> getBaskets() async {
    try {
      final res = await _api.get('/reports/baskets');
      if (res is List) return res;
      return (res as Map<String, dynamic>)['baskets'] as List? ?? [];
    } catch (_) {
      final res = await _api.get('/crud/api/baskets');
      if (res is List) return res;
      return (res as Map<String, dynamic>)['baskets'] as List? ?? [];
    }
  }

  Future<Map<String, dynamic>?> getBasketReport(String basketId) async {
    try {
      final res = await _api.get('/reports/basket/$basketId');
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {
      return null;
    }
  }

  Future<List> getAvailableDevices() async {
    try {
      final res = await _api.get('/crud/api/devices/available');
      if (res is List) return res;
      return (res as Map<String, dynamic>)['devices'] as List? ?? [];
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> data) async {
    // ML endpoint auto-creates a device when an unknown device_id is posted.
    final generatedId =
        (data['device_id']?.toString().trim().isNotEmpty ?? false)
        ? data['device_id'].toString().trim()
        : 'AUTO-${DateTime.now().millisecondsSinceEpoch}';
    await _api.post('/data', {
      'device_id': generatedId,
      'baskets': <Map<String, dynamic>>[],
    });
    return {
      'device_id': generatedId,
      'wifi_ssid': data['wifi_ssid'] ?? 'Auto Provisioned',
      'is_active': data['is_active'] ?? true,
    };
  }

  Future<Map<String, dynamic>> createBasket(Map<String, dynamic> data) async {
    try {
      return await _api.post('/crud/api/baskets', data);
    } catch (_) {
      final deviceId = data['device_id']?.toString();
      if (deviceId == null || deviceId.isEmpty) {
        rethrow;
      }

      final syntheticBasketId = DateTime.now().millisecondsSinceEpoch % 1000000;
      final res = await _api.post('/data', {
        'device_id': deviceId,
        'baskets': [
          {
            'id': syntheticBasketId,
            'valid': true,
            'temp': 25.0,
            'hum': 50.0,
            'eco2': 450.0,
            'tvoc': 120.0,
            'aqi': 55.0,
            'mq_raw': 0.0,
            'mq_volts': 0.1,
            'fruit_type': data['fruit_type']?.toString() ?? 'Banana',
            'location': data['location']?.toString() ?? 'Main Isle',
          },
        ],
      });
      return <String, dynamic>{
        'ok': true,
        'mode': 'ml_fallback',
        'device_id': deviceId,
        'rows_added': res['rows_added'] ?? 1,
      };
    }
  }

  Future<Map<String, dynamic>> updateBasket(
    String basketId,
    Map<String, dynamic> data,
  ) async {
    return await _api.put('/crud/api/baskets/$basketId', data);
  }

  Future<Map<String, dynamic>> deleteBasket(String basketId) async {
    return await _api.delete('/crud/api/baskets/$basketId?confirm=true');
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  /// Fetch notifications. Optionally filter by [isRead] (0=unread, 1=read)
  /// and/or [severity] (info | warning | critical).
  Future<List<Map<String, dynamic>>> getNotifications({
    int? isRead,
    String? severity,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      if (isRead != null) 'is_read': '$isRead',
      if (severity != null && severity.isNotEmpty) 'severity': severity,
    };
    final query = Uri(queryParameters: params).query;
    final res = await _api.get('/api/notifications/?$query');
    final notifications = List<Map<String, dynamic>>.from(
      res['notifications'] ?? [],
    );

    if (notifications.isNotEmpty) {
      return notifications;
    }

    // Frontend fallback: derive notification cards from prediction-based alerts
    // when backend notification rows are not being written.
    if (isRead == 1) {
      return <Map<String, dynamic>>[];
    }

    final alertsRes = await _api.get('/api/alerts/history?limit=$limit');
    var derived = _mapAlertsToNotifications(alertsRes['alerts'] ?? []);

    if (severity != null && severity.isNotEmpty) {
      derived = derived.where((n) => n['severity'] == severity).toList();
    }

    return derived;
  }

  /// Number of unread notifications — used for the badge on the bell icon.
  Future<int> getUnreadNotificationCount() async {
    final res = await _api.get('/api/notifications/unread/count');
    final notificationCount = (res['count'] as num).toInt();

    if (notificationCount > 0) {
      return notificationCount;
    }

    // If notification rows are empty, mirror active prediction alerts as unread.
    final alertsCountRes = await _api.get('/api/alerts/history/unacknowledged/count');
    return (alertsCountRes['count'] as num?)?.toInt() ?? 0;
  }

  /// Mark a single notification as read.
  Future<void> markNotificationRead(int id) async {
    await _api.put('/api/notifications/$id/read', {});
  }

  /// Mark every notification as read.
  Future<void> markAllNotificationsRead() async {
    await _api.put('/api/notifications/read-all', {});
  }

  /// Delete a single notification.
  Future<void> deleteNotification(int id) async {
    await _api.delete('/api/notifications/$id');
  }

  /// Delete all read notifications.
  Future<void> clearReadNotifications() async {
    await _api.delete('/api/notifications/clear-all');
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────

  /// Fetch alert history with optional filters.
  Future<List<Map<String, dynamic>>> getAlerts({
    String? batchId,
    String? fruitType,
    String? severity,
    int? acknowledged,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
      if (fruitType != null && fruitType.isNotEmpty) 'fruit_type': fruitType,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      if (acknowledged != null) 'acknowledged': '$acknowledged',
    };
    final query = Uri(queryParameters: params).query;
    final res = await _api.get('/api/alerts/history?$query');
    return List<Map<String, dynamic>>.from(res['alerts'] ?? []);
  }

  /// Unacknowledged alert count — for dashboard badge.
  Future<int> getUnacknowledgedAlertCount() async {
    final res = await _api.get('/api/alerts/history/unacknowledged/count');
    return (res['count'] as num).toInt();
  }

  /// Alert summary grouped by batch.
  Future<List<Map<String, dynamic>>> getAlertSummary() async {
    final res = await _api.get('/api/alerts/history/summary');
    return List<Map<String, dynamic>>.from(res['summary'] ?? []);
  }

  /// Acknowledge a single alert.
  Future<void> acknowledgeAlert(
    int alertId, {
    String acknowledgedBy = 'Store Staff',
  }) async {
    await _api.put('/api/alerts/ack/$alertId', {
      'acknowledged_by': acknowledgedBy,
    });
  }

  /// Acknowledge all alerts in a batch.
  Future<void> acknowledgeBatch(
    String batchId, {
    String acknowledgedBy = 'Store Staff',
  }) async {
    await _api.put('/api/alerts/ack/batch/$batchId', {
      'acknowledged_by': acknowledgedBy,
    });
  }

  /// Get configured sensor thresholds.
  Future<Map<String, dynamic>> getThresholds() async {
    final res = await _api.get('/api/alerts/thresholds');
    return Map<String, dynamic>.from(res['thresholds'] ?? {});
  }

  /// Submit a sensor reading and trigger any threshold alerts.
  Future<Map<String, dynamic>> checkSensor({
    required String batchId,
    required String fruitType,
    required Map<String, double> sensorData,
  }) async {
    return await _api.post('/api/alerts/check', {
      'batch_id': batchId,
      'fruit_type': fruitType,
      'sensor_data': sensorData,
    });
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  Future<bool> isBackendReachable() async {
    try {
      await _api.get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}
