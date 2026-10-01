import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  final ApiService _api;
  List<SessionModel> _activeSessions = [];
  // Sesi yang sudah dihentikan server (waktu habis) tapi belum di-checkout di
  // tablet ini. Disimpan agar refresh tidak menghilangkan kartu sebelum dibayar.
  final Map<String, SessionModel> _awaitingCheckout = {};
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
      final fetched = raw.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();

      final fetchedIds = fetched.map((s) => s.id).toSet();
      for (final s in _activeSessions) {
        if (!fetchedIds.contains(s.id)) _awaitingCheckout[s.id] = s;
      }
      _awaitingCheckout.removeWhere((id, _) => fetchedIds.contains(id));

      _activeSessions = [...fetched, ..._awaitingCheckout.values];
    } catch (e) {
      _error = 'Gagal memuat sesi: ${_parseError(e)}';
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
      _error = _parseError(e);
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
        _removeLocal(sessionId);
        notifyListeners();
        return updated;
      }
      throw Exception(res['message']);
    } catch (e) {
      // Sesi sudah tidak ada di server: buang dari layar agar kartu tidak macet
      if (e is DioException && e.response?.statusCode == 404) {
        _removeLocal(sessionId);
      }
      _error = _parseError(e);
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
      _error = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  void _removeLocal(String sessionId) {
    _activeSessions.removeWhere((s) => s.id == sessionId);
    _awaitingCheckout.remove(sessionId);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (e.response == null) return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return 'Server error (${e.response?.statusCode})';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
