import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UnitProvider extends ChangeNotifier {
  final ApiService _api;
  List<UnitModel> _units = [];
  bool _isLoading = false;
  String? _error;

  UnitProvider(this._api);

  List<UnitModel> get units       => _units;
  bool get isLoading              => _isLoading;
  String? get error               => _error;
  List<UnitModel> get availableUnits => _units.where((u) => u.isAvailable).toList();
  List<UnitModel> get activeUnits    => _units.where((u) => u.isInUse).toList();

  Future<void> fetchUnits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getUnits();
      final raw = res['data'] as List;
      _units = raw.map((e) => UnitModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Gagal memuat unit: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUnitStatus(String unitId, String newStatus) {
    final idx = _units.indexWhere((u) => u.id == unitId);
    if (idx != -1) {
      // refresh list dari server untuk data terkini
      fetchUnits();
    }
  }

  Future<bool> createUnit(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.createUnit(data);
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Gagal membuat unit: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUnit(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateUnit(id, data);
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Gagal mengupdate unit: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reorderUnits(List<UnitModel> reorderedList) async {
    // Optimistic update locally
    final oldUnits = List<UnitModel>.from(_units);
    _units = reorderedList;
    notifyListeners();

    try {
      final orders = reorderedList.asMap().entries.map((e) => {
        'id': e.value.id,
        'displayOrder': e.key
      }).toList();
      
      await _api.reorderUnits(orders);
      return true;
    } catch (e) {
      _units = oldUnits; // Rollback if failed
      _error = 'Gagal memperbarui urutan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnit(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.deleteUnit(id);
      await fetchUnits();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus unit: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
