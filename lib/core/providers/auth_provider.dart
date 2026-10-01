import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final SharedPreferences _prefs;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._api, this._prefs) {
    _loadStoredSession();
    
    _api.onForceLogout = logout;
    _api.onTokenRefreshed = (newAccess, newRefresh) {
      _prefs.setString(AppConstants.keyAccessToken, newAccess);
      _prefs.setString(AppConstants.keyRefreshToken, newRefresh);
    };
  }

  UserModel? get user     => _user;
  bool get isLoading      => _isLoading;
  String? get error       => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin        => _user?.isAdmin ?? false;

  void _loadStoredSession() {
    final token = _prefs.getString(AppConstants.keyAccessToken);
    final refreshToken = _prefs.getString(AppConstants.keyRefreshToken);
    final userJson = _prefs.getString(AppConstants.keyUser);
    if (token != null && refreshToken != null && userJson != null) {
      _api.setTokens(token, refreshToken);
      _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final accessToken  = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        final userData     = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        _api.setTokens(accessToken, refreshToken);
        await _prefs.setString(AppConstants.keyAccessToken, accessToken);
        await _prefs.setString(AppConstants.keyRefreshToken, refreshToken);
        await _prefs.setString(AppConstants.keyUser, jsonEncode(userData.toJson()));

        _user = userData;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw Exception(res['message'] ?? 'Login gagal');
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}

    _api.clearTokens();
    await _prefs.remove(AppConstants.keyAccessToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUser);
    _user = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response!.data['message']?.toString() ?? e.toString();
    }
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
