import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage;

  // Use your machine's LAN IP so real devices and emulators can connect.
  // For Android emulator only, override with 'http://10.0.2.2:8000/api/v1'.
  static const String _defaultBaseUrl = 'https://tugas-besar-webdanmobile.vercel.app/api/v1';

  ApiClient({
    String baseUrl = _defaultBaseUrl,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Retrieve Sanctum token from secure storage
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // ignore: avoid_print
          print('[API Error] ${e.type} - ${e.message}');
          if (e.response != null) {
            // ignore: avoid_print
            print('[API Error] Status: ${e.response!.statusCode} - Body: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Helper getters for REST actions
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.delete(path, data: data, queryParameters: queryParameters);
  }
}
