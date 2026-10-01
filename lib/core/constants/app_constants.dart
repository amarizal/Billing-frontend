class AppConstants {
  // ─── API ────────────────────────────────────────────────
  static String baseUrl = 'https://billing-backend-production-7ed4.up.railway.app/api';

  // ─── Storage Keys ────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';

  // ─── Session ─────────────────────────────────────────────
  // Timer berubah warna peringatan saat sisa waktu di bawah ini (menit)
  static const int sessionWarningMinutes = 5;
}
