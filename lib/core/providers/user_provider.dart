import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _api;
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  UserProvider(this._api);

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getUsers();
      if (res['success'] == true) {
        final list = res['data'] as List;
        _users = list.map((e) => UserModel.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        _error = e.response!.data['message']?.toString() ?? e.toString();
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.createUser(data);
      if (res['success'] == true) {
        await fetchUsers();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        _error = e.response!.data['message']?.toString() ?? e.toString();
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateUser(id, data);
      if (res['success'] == true) {
        await fetchUsers();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        _error = e.response!.data['message']?.toString() ?? e.toString();
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteUser(id);
      await fetchUsers();
      return true;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        _error = e.response!.data['message']?.toString() ?? e.toString();
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
