import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  final ApiService _api;
  List<SessionModel> _activeSessions = [];
  bool _isLoading = false;
  String? _error;
  String? _tuyaWarning;

  SessionProvider(this._api);

  List<SessionModel> get activeSessions => _activeSessions;
  bool get isLoading => _isLoading;
  String? get error  => _error;
  String? get tuyaWarning => _tuyaWarning;

  SessionModel? sessionForUnit(String unitId) =>
      _activeSessions.where((s) => s.unitId == unitId).firstOrNull;

  Future<void> fetchActiveSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getActiveSessions();
      final raw = res['data'] as List;
      _activeSessions = raw.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Gagal memuat sesi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SessionModel?> startSession(String unitId, String packageId) async {
    _tuyaWarning = null;
    try {
      final res = await _api.startSession(unitId, packageId);
      if (res['success'] == true) {
        _tuyaWarning = res['warning'] as String?;
        final session = SessionModel.fromJson(res['data'] as Map<String, dynamic>);
        _activeSessions.add(session);
        notifyListeners();
        return session;
      }
      throw Exception(res['message']);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<SessionModel?> stopSession(String sessionId) async {
    _tuyaWarning = null;
    try {
      final res = await _api.stopSession(sessionId);
      if (res['success'] == true) {
        _tuyaWarning = res['warning'] as String?;
        final updated = SessionModel.fromJson(res['data'] as Map<String, dynamic>);
        _activeSessions.removeWhere((s) => s.id == sessionId);
        notifyListeners();
        return updated;
      }
      throw Exception(res['message']);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<SessionModel?> extendSession(String sessionId, String packageId) async {
    _tuyaWarning = null;
    try {
      final res = await _api.extendSession(sessionId, packageId);
      if (res['success'] == true) {
        _tuyaWarning = res['warning'] as String?;
        final extended = SessionModel.fromJson(res['data'] as Map<String, dynamic>);
        final index = _activeSessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          _activeSessions[index] = extended;
        }
        notifyListeners();
        return extended;
      }
      throw Exception(res['message']);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
