import 'package:flutter/foundation.dart';

class AppConstants {
  // ─── API ────────────────────────────────────────────────
  static String baseUrl = 'https://billing-backend-production-7ed4.up.railway.app/api';

  // ─── Storage Keys ────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';

  // ─── Session ─────────────────────────────────────────────
  // Notifikasi peringatan sebelum sesi habis (menit)
  static const int sessionWarningMinutes = 5;

  // ─── Pagination ──────────────────────────────────────────
  static const int defaultPageSize = 50;
}
