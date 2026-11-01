import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'network_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

class ApiClient {
  ApiClient(SecureStorage storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: _apiBaseUrl(),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.addAll([
      // _ErrorInterceptor MUST come before AuthInterceptor in the list.
      // Dio processes error interceptors in REVERSE order (last added = first to handle error).
      // So AuthInterceptor (added last here) will receive the 401 first,
      // attempt the token refresh, and only if that fails does _ErrorInterceptor remap it.
      _ErrorInterceptor(),
      AuthInterceptor(storage, dio),
      if (kDebugMode) PrettyDioLogger(requestBody: true, responseBody: false),
    ]);
  }

  final Dio dio;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await dio.get<List<dynamic>>(
        path,
        queryParameters: query,
      );
      return response.data ?? <dynamic>[];
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  Future<Map<String, dynamic>> postMap(String path, {Object? data}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  Future<Map<String, dynamic>> patchMap(String path, {Object? data}) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  Future<Map<String, dynamic>> deleteMap(String path, {Object? data}) async {
    try {
      final response = await dio.delete<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  Object _unwrapException(DioException e) {
    if (e.error != null) {
      return e.error!;
    }
    return e;
  }
}

String _apiBaseUrl() {
  try {
    final url = dotenv.maybeGet('API_BASE_URL') ?? '';
    if (url.isEmpty) {
      debugPrint('⚠️  API_BASE_URL not set in .env — using fallback');
      return 'http://localhost:4000/api/v1';
    }
    // Warn in debug mode if the URL is a hardcoded LAN IP
    // (will only work on the same WiFi as the backend machine)
    if (kDebugMode && RegExp(r'http://192\.168\.|http://10\.|http://172\.').hasMatch(url)) {
      debugPrint(
        '⚠️  API_BASE_URL is a local LAN IP ($url).\n'
        '   This only works on the same WiFi as your backend machine.\n'
        '   For demos on other networks: run `ngrok http 4000` and update .env',
      );
    }
    return url;
  } catch (_) {
    return 'http://localhost:4000/api/v1';
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final NetworkException mapped;
    if (statusCode == 401) {
      mapped = const UnauthorizedException();
    } else if (statusCode == 400) {
      String backendMessage = 'Invalid request';
      if (err.response?.data is Map) {
        final data = err.response!.data as Map;
        final msgRaw = data['message'] ?? data['error'];
        if (msgRaw is String) {
          backendMessage = msgRaw;
        } else if (msgRaw is List && msgRaw.isNotEmpty) {
          // NestJS class-validator returns an array of constraint messages.
          // Join them so the user sees "productId must be a UUID, ..."
          backendMessage = (msgRaw).map((e) => e.toString()).join('\n');
        }
      }
      mapped = ServerException(backendMessage);
    } else if (statusCode == 404) {
      mapped = const NotFoundException();
    } else if (statusCode == 422) {
      mapped = ValidationException(_readValidationErrors(err.response?.data));
    } else if (statusCode != null && statusCode >= 500) {
      mapped = const ServerException(
        'SmartVital is temporarily unavailable. Please try again.',
      );
    } else if (err.error is NetworkException) {
      mapped = err.error! as NetworkException;
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.error?.toString().contains('SocketException') ?? false) ||
        (err.error?.toString().contains('Failed host lookup') ?? false) ||
        (err.message?.contains('Failed host lookup') ?? false) ||
        (err.message?.contains('SocketException') ?? false)) {
      mapped = const NetworkUnavailableException();
    } else {
      mapped = ServerException(
        err.message ?? 'We could not complete that request.',
      );
    }
    handler.reject(
      DioException(requestOptions: err.requestOptions, error: mapped),
    );
  }

  Map<String, String> _readValidationErrors(Object? data) {
    if (data is! Map || data['errors'] is! Map) return const {};
    return Map<String, String>.from(data['errors'] as Map);
  }
}
