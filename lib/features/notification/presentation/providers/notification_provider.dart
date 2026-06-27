import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'notification_service.dart';

class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['is_read'] == true,
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  String get displayTitle {
    switch (type) {
      case 'message':
        return 'Pesan dari ${data['sender_name'] ?? 'Seseorang'}';
      case 'post_comment':
        return 'Komentar baru';
      case 'post_reaction':
        return 'Reaksi pada postingan Anda';
      case 'forum_invitation':
        return 'Undangan Forum';
      case 'forum_kick':
        return 'Dikeluarkan dari Forum';
      default:
        return data['title'] ?? 'Notifikasi Baru';
    }
  }

  String get displayBody {
    switch (type) {
      case 'message':
        return data['conversation_name'] is String
            ? '${data['sender_name'] ?? 'Seseorang'}: ${data['body'] ?? 'Mengirim file'}'
            : (data['body'] ?? 'Pesan baru');
      case 'post_comment':
        return '${data['comment_by_name'] ?? 'Seseorang'} berkomentar: "${data['comment'] ?? ''}"';
      case 'post_reaction':
        return '${data['reacted_by_name'] ?? 'Seseorang'} memberikan ${data['reaction_type'] ?? 'reaksi'}';
      case 'forum_invitation':
        return 'Anda diundang ke forum ${data['forum_name'] ?? ''}';
      case 'forum_kick':
        return 'Anda telah dikeluarkan dari forum ${data['forum_name'] ?? ''}';
      default:
        return data['message'] ?? data['body'] ?? '';
    }
  }
}

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> seenIds;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.seenIds = const {},
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    Set<String>? seenIds,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      seenIds: seenIds ?? this.seenIds,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;
  Timer? _pollTimer;
  int _notifIdCounter = 0;

  NotificationNotifier(this._apiClient) : super(const NotificationState());

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      loadUnreadCount();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/notifications');
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        final unread = list.where((n) => !n.isRead).length;
        state = state.copyWith(notifications: list, unreadCount: unread, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      if (response.data['success'] == true) {
        final raw = response.data['data'];
        final count = (raw is Map) ? (raw['count'] ?? raw['unread_count'] ?? 0) : 0;
        final prevCount = state.unreadCount;
        if (count > prevCount) {
          final newCount = count - prevCount;
          await _showNotificationForNew(newCount);
          await loadNotifications();
        }
        state = state.copyWith(unreadCount: count);
      }
    } catch (_) {}
  }

  Future<void> _showNotificationForNew(int newCount) async {
    try {
      final response = await _apiClient.get('/notifications', queryParameters: {'limit': '1'});
      if (response.data['success'] == true) {
        final list = response.data['data'] as List?;
        if (list != null && list.isNotEmpty) {
          final notif = NotificationModel.fromJson(list[0]);
          if (!state.seenIds.contains(notif.id)) {
            final newSeen = Set<String>.from(state.seenIds)..add(notif.id);
            state = state.copyWith(seenIds: newSeen);
            _notifIdCounter++;
            await showLocalNotification(
              id: _notifIdCounter,
              title: notif.displayTitle,
              body: notif.displayBody,
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put('/notifications/$notificationId/read');
      if (response.data['success'] == true) {
        final list = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
          }
          return n;
        }).toList();
        final unread = list.where((n) => !n.isRead).length;
        state = state.copyWith(notifications: list, unreadCount: unread);
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.put('/notifications/read-all');
      if (response.data['success'] == true) {
        final list = state.notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
        }).toList();
        state = state.copyWith(notifications: list, unreadCount: 0);
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete('/notifications/$notificationId');
      if (response.data['success'] == true) {
        final list = state.notifications.where((n) => n.id != notificationId).toList();
        final unread = list.where((n) => !n.isRead).length;
        state = state.copyWith(notifications: list, unreadCount: unread);
      }
    } catch (_) {}
  }

  Future<void> deleteAllNotifications() async {
    try {
      final response = await _apiClient.delete('/notifications');
      if (response.data['success'] == true) {
        state = state.copyWith(notifications: [], unreadCount: 0);
      }
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return NotificationNotifier(apiClient);
});
