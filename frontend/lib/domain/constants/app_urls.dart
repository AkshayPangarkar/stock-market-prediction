import 'package:flutter/foundation.dart';

class AppUrls {
   static const String _override = String.fromEnvironment('API_HOST');

  static String get _host {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000"; // emulator
    }
    return "http://127.0.0.1:8000";
  }

  static final String baseUrl="http://127.0.0.1:8000/api";

  static final String registeurl="$baseUrl/v1/register/";
  static final String loginUrl="$baseUrl/v1/token/";
  static String get refreshUrl => "$baseUrl/v1/token/refresh/";
  static String get stockPredictUrl => "$baseUrl/v1/stock/predict/";
static String get stockTodayUrl => "$baseUrl/v1/stock/today/";
}