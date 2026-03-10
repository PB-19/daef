import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/models/api_response.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage));
  }

  Dio get dio => _dio;

  // ── Convenience wrappers ─────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _safeCall(() => _dio.get(path, queryParameters: params));

  Future<Response> post(String path, {dynamic data}) =>
      _safeCall(() => _dio.post(path, data: data));

  Future<Response> patch(String path, {dynamic data}) =>
      _safeCall(() => _dio.patch(path, data: data));

  Future<Response> delete(String path, {Map<String, dynamic>? params}) =>
      _safeCall(() => _dio.delete(path, queryParameters: params));

  Future<Response> _safeCall(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiError _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiError(message: 'Connection timed out. Please try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiError(message: 'No connection to server. Check your network.');
    }

    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    String message = 'Something went wrong.';
    String? detail;

    if (body is Map<String, dynamic>) {
      detail = body['detail'] as String? ?? body['error'] as String?;
      message = detail ?? message;
    }

    return ApiError(message: message, statusCode: statusCode, detail: detail);
  }
}

// ── Auth interceptor — attaches token and handles 401 ────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  // Paths that don't need auth headers
  static const _publicPaths = {'/auth/login', '/auth/register'};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isPublic = _publicPaths.any((p) => path.endsWith(p));

    if (!isPublic) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Clear token — providers will react and route to login
      _storage.delete(key: AppConstants.tokenKey);
    }
    handler.next(err);
  }
}
