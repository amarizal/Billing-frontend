import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PosProvider extends ChangeNotifier {
  final ApiService _api;

  List<PosCategoryModel> _categories = [];
  final List<CartItem> _cart = [];
  bool _isLoading = false;
  String? _error;

  PosProvider(this._api);

  List<PosCategoryModel> get categories => _categories;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get cartIsEmpty => _cart.isEmpty;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);

  String get cartTotalDisplay =>
      'Rp ${cartTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getPosCategories();
      final raw = res['data'] as List;
      _categories = raw
          .map((e) => PosCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Gagal memuat menu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Admin Management ───────────────────────────────────
  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      await _api.createPosCategory(data);
      await fetchCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _api.updatePosCategory(id, data);
      await fetchCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createItem(Map<String, dynamic> data) async {
    try {
      await _api.createPosItem(data);
      await fetchCategories(); // refresh data
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _api.updatePosItem(id, data);
      await fetchCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _api.deletePosItem(id);
      await fetchCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void reorderItems(List<PosItemModel> flatItems) {
    for (var cat in _categories) {
      cat.items.sort((a, b) {
        final idxA = flatItems.indexWhere((item) => item.id == a.id);
        final idxB = flatItems.indexWhere((item) => item.id == b.id);
        return idxA.compareTo(idxB);
      });
    }
    notifyListeners();
  }

  // ─── Cart Management ────────────────────────────────────
  void addToCart(PosItemModel item) {
    _error = null;
    final idx = _cart.indexWhere((c) => c.item.id == item.id);
    
    // Validasi stok jika manage stock diaktifkan (stock != null)
    if (item.stock != null) {
      final currentInCart = idx != -1 ? _cart[idx].quantity : 0;
      if (currentInCart >= item.stock!) {
        _error = 'Stok tidak mencukupi untuk ${item.name}';
        notifyListeners();
        return;
      }
    }

    if (idx != -1) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    final idx = _cart.indexWhere((c) => c.item.id == itemId);
    if (idx != -1) {
      if (_cart[idx].quantity > 1) {
        _cart[idx].quantity--;
      } else {
        _cart.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void removeItemCompletely(String itemId) {
    _cart.removeWhere((c) => c.item.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<PosOrderModel?> submitOrder({String? sessionId}) async {
    if (_cart.isEmpty) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final items = _cart
          .map((c) => {
                'itemId': c.item.id,
                'quantity': c.quantity,
              })
          .toList();

      final res = await _api.createPosOrder({
        if (sessionId != null) 'sessionId': sessionId,
        'items': items,
      });

      if (res['success'] == true) {
        final order = PosOrderModel.fromJson(res['data'] as Map<String, dynamic>);
        clearCart();
        return order;
      }
      throw Exception(res['message']);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        _error = e.response!.data['message']?.toString() ?? e.toString();
      } else {
        _error = e.toString();
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
