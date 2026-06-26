import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      state = state.copyWith(isLoading: true);
      try {
        final response = await _apiClient.get('/auth/me');
        if (response.data['success'] == true) {
          state = AuthState(
            isAuthenticated: true,
            token: token,
            user: response.data['data'],
          );
        } else {
          await _storage.delete(key: 'auth_token');
          state = const AuthState();
        }
      } catch (e) {
        // network error, let user keep session locally for now or reset
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];
        await _storage.write(key: 'auth_token', value: token);
        state = AuthState(
          isAuthenticated: true,
          token: token,
          user: user,
        );
        _registerDeviceToken(); // fire-and-forget
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.data['message'] ?? 'Login gagal.',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'Login gagal.')
          : 'Koneksi gagal. Periksa koneksi internet Anda.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Koneksi gagal. Periksa koneksi internet Anda.',
      );
      return false;
    }
  }

  Future<bool> register(String username, String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (response.data['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.data['message'] ?? 'Registrasi gagal.',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'Registrasi gagal.')
          : 'Gagal menghubungkan ke server.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghubungkan ke server.',
      );
      return false;
    }
  }

  Future<bool> registerDeviceToken(String deviceToken) async {
    try {
      final response = await _apiClient.post('/device-tokens', data: {
        'device_token': deviceToken,
        'platform': 'android',
      });
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      const uuid = Uuid();
      String deviceId = await _storage.read(key: 'device_id') ?? '';
      if (deviceId.isEmpty) {
        deviceId = uuid.v4();
        await _storage.write(key: 'device_id', value: deviceId);
      }
      await _apiClient.post('/device-tokens', data: {
        'device_token': deviceId,
        'platform': 'android',
      });
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.data['success'] == true) {
        state = state.copyWith(user: response.data['data']);
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
    state = const AuthState();
  }
}

// Providers
final apiProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return AuthNotifier(apiClient);
});
