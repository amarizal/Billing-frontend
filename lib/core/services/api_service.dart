import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  String? _accessToken;

  String? _refreshToken;
  void Function()? onForceLogout;
  void Function(String accessToken, String refreshToken)? onTokenRefreshed;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Request interceptor: inject token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            // Gunakan instance Dio baru agar tidak terkena interceptor yang sama
            final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
            final res = await refreshDio.post('/auth/refresh', data: {'refreshToken': _refreshToken});
            
            if (res.statusCode == 200 || res.statusCode == 201) {
              final data = res.data['data'] as Map<String, dynamic>;
              final newAccess = data['accessToken'] as String;
              final newRefresh = data['refreshToken'] as String;
              
              _accessToken = newAccess;
              _refreshToken = newRefresh;
              onTokenRefreshed?.call(newAccess, newRefresh);
              
              // Retry request asli yang gagal
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final retryRes = await refreshDio.fetch(opts);
              return handler.resolve(retryRes);
            }
          } catch (e) {
            // Jika refresh gagal, trigger force logout
            onForceLogout?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ─── Auth ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/auth/login', data: {'username': username, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  // ─── Units ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUnits() async {
    final res = await _dio.get('/units');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final res = await _dio.post('/units', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUnit(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/units/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reorderUnits(List<Map<String, dynamic>> orders) async {
    final res = await _dio.post('/units/reorder', data: {'orders': orders});
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteUnit(String id) async {
    await _dio.delete('/units/$id');
  }

  // ─── Packages ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getPackages({String? unitType}) async {
    final res = await _dio.get('/packages',
        queryParameters: unitType != null ? {'applicableTo': unitType} : null);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    final res = await _dio.post('/packages', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePackage(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/packages/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deletePackage(String id) async {
    await _dio.delete('/packages/$id');
  }

  // ─── Sessions ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getActiveSessions() async {
    final res = await _dio.get('/sessions/active');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startSession(String unitId, String packageId) async {
    final res = await _dio.post('/sessions/start', data: {'unitId': unitId, 'packageId': packageId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stopSession(String sessionId) async {
    final res = await _dio.put('/sessions/$sessionId/stop');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extendSession(String sessionId, String packageId) async {
    final res = await _dio.put('/sessions/$sessionId/extend', data: {'packageId': packageId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final res = await _dio.get('/sessions/$sessionId');
    return res.data as Map<String, dynamic>;
  }

  // ─── POS ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPosCategories() async {
    final res = await _dio.get('/pos/categories');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPosCategory(Map<String, dynamic> data) async {
    final res = await _dio.post('/pos/categories', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePosCategory(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/pos/categories/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPosItems({String? categoryId}) async {
    final res = await _dio.get('/pos/items',
        queryParameters: categoryId != null ? {'categoryId': categoryId} : null);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPosItem(Map<String, dynamic> data) async {
    final res = await _dio.post('/pos/items', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePosItem(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/pos/items/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deletePosItem(String id) async {
    await _dio.delete('/pos/items/$id');
  }

  Future<Map<String, dynamic>> createPosOrder(Map<String, dynamic> data) async {
    final res = await _dio.post('/pos/orders', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ─── Receipts ─────────────────────────────────────────────
  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> data) async {
    final res = await _dio.post('/receipts', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReceipt(String id) async {
    final res = await _dio.get('/receipts/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markReceiptPrinted(String id) async {
    final res = await _dio.patch('/receipts/$id/print');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteReceipt(String id) async {
    await _dio.delete('/receipts/$id');
  }

  // ─── Reports ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getDailyReport(String date) async {
    final res = await _dio.get('/reports/daily', queryParameters: {'date': date});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    final res = await _dio.get('/reports/monthly',
        queryParameters: {'year': year, 'month': month});
    return res.data as Map<String, dynamic>;
  }

  // ─── Users ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUsers() async {
    final res = await _dio.get('/users');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post('/users', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/users/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }
}
