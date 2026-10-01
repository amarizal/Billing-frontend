import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _api;
  
  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _monthlyReport;
  bool _isLoading = false;
  String? _error;

  ReportProvider(this._api);

  Map<String, dynamic>? get dailyReport => _dailyReport;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDailyReport(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _api.getDailyReport(dateStr);
      if (res['success'] == true) {
        _dailyReport = res['data'] as Map<String, dynamic>;
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Gagal memuat laporan harian: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyReport(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getMonthlyReport(date.year, date.month);
      if (res['success'] == true) {
        _monthlyReport = res['data'] as Map<String, dynamic>;
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Gagal memuat laporan bulanan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
