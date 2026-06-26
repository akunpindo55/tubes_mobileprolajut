import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(const ProfileState());

  Future<void> loadProfile(String username) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/users/$username');
      if (response.data['success'] == true) {
        state = state.copyWith(profile: response.data['data'], isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final response = await _apiClient.put('/users/profile', data: data);
      if (response.data['success'] == true) {
        state = state.copyWith(profile: response.data['data'], isSaving: false);
        return true;
      } else {
        state = state.copyWith(isSaving: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final response = await _apiClient.put('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
      if (response.data['success'] == true) {
        state = state.copyWith(isSaving: false);
        return true;
      } else {
        state = state.copyWith(isSaving: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> blockUser(int userId) async {
    try {
      final response = await _apiClient.post('/users/$userId/block');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final response = await _apiClient.post('/users/$userId/unblock');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    // File upload skipped as requested
  }

  void clear() {
    state = const ProfileState();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return ProfileNotifier(apiClient);
});
