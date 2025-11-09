import 'package:dio/dio.dart';

import '../config.dart';

class ApiClient {
  ApiClient(this.config, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _normalizeBaseUrl(config),
              connectTimeout: config.connectTimeout,
              receiveTimeout: config.receiveTimeout,
              headers: _resolveHeaders(config),
              responseType: ResponseType.json,
            ),
          );

  final Config config;
  final Dio _dio;

  static Map<String, Object?> _resolveHeaders(Config config) {
    final headers = <String, String>{...config.defaultHeaders};
    final token = config.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _normalizeBaseUrl(Config config) {
    final raw = config.serverUrl.toString();
    return raw.endsWith('/') ? raw : '$raw/';
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? query,
    dynamic data,
  }) async {
    return _dio.post<dynamic>(path, data: data, queryParameters: query);
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _dio.get<dynamic>(path, queryParameters: query);
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _dio.delete<dynamic>(path, queryParameters: query);
  }

  Future<Response<dynamic>> patch(
    String path, {
    Map<String, dynamic>? query,
    dynamic data,
  }) async {
    return _dio.patch<dynamic>(path, data: data, queryParameters: query);
  }
}
