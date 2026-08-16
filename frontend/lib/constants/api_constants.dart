import 'package:flutter/foundation.dart';

/// Networking constants for the Laravel backend.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    const defaultBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      // Keep base URL without trailing `/api` to avoid duplication when
      // combining with `apiVersion` below.
      defaultValue: 'your_linked_railway_app_url_here', 
    );

    return defaultBaseUrl.isNotEmpty ? defaultBaseUrl : 'your_linked_railway_app_url_here';
  }

  static const String apiVersion = 'api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static String get apiBaseUrl => '$baseUrl/$apiVersion';
}
