import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PackageProvider extends ChangeNotifier {
  final ApiService _api;
  List<PackageModel> _packages = [];
  bool _isLoading = false;
  String? _error;

  PackageProvider(this._api);

  List<PackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error  => _error;

  Future<void> fetchPackages({String? unitType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getPackages(unitType: unitType);
      final raw = res['data'] as List;
      _packages = raw.map((e) => PackageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Gagal memuat paket: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPackage(Map<String, dynamic> data) async {
    try {
      await _api.createPackage(data);
      await fetchPackages();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePackage(String id, Map<String, dynamic> data) async {
    try {
      await _api.updatePackage(id, data);
      await fetchPackages();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePackage(String id) async {
    try {
      await _api.deletePackage(id);
      await fetchPackages();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> reorderPackages(List<PackageModel> newOrder) async {
    _packages = newOrder;
    notifyListeners();
  }
}
