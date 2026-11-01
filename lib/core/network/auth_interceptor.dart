import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'network_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final SecureStorage _storage;
  final Dio _dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(SecureStorage.accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read('refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
          final response = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
          
          final newAccessToken = response.data['accessToken'] as String? ?? '';
          final newRefreshToken = response.data['refreshToken'] as String?;
          
          await _storage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
          
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(options);
          return handler.resolve(retryResponse);
        } catch (_) {
          return handler.reject(DioException(requestOptions: err.requestOptions, error: const UnauthorizedException()));
        }
      }
      return handler.reject(DioException(requestOptions: err.requestOptions, error: const UnauthorizedException()));
    }
    handler.next(err);
  }
}
