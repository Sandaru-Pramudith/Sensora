import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const railwayUrl = 'https://sensora-production-0e73.up.railway.app';

    if (kIsWeb) {
      return railwayUrl;
    }

    if (Platform.isAndroid) {
      return railwayUrl;
    }

    return railwayUrl;
  }
}
