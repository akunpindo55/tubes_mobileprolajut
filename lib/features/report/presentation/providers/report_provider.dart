import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReportState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const ReportState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  ReportState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ApiClient _apiClient;

  ReportNotifier(this._apiClient) : super(const ReportState());

  Future<bool> submitReport({
    required String reportableType,
    required int reportableId,
    required String reason,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    try {
      final response = await _apiClient.post('/reports', data: {
        'reportable_type': reportableType,
        'reportable_id': reportableId,
        'reason': reason,
        if (description != null) 'description': description,
      });
      if (response.data['success'] == true) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ReportState();
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return ReportNotifier(apiClient);
});
