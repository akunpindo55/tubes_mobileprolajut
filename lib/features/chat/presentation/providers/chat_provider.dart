import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ConversationModel {
  final int id;
  final String name;
  final String? description;
  final String type;
  final int? createdBy;
  final String? avatar;
  final Map<String, dynamic>? lastMessage;
  final List<dynamic>? members;

  ConversationModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.createdBy,
    this.avatar,
    this.lastMessage,
    this.members,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      name: json['name'] ?? 'Direct Chat',
      description: json['description'],
      type: json['type'],
      createdBy: json['created_by'],
      avatar: json['avatar'],
      lastMessage: json['last_message'],
      members: json['members'],
    );
  }
}

class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String messageType;
  final String? body;
  final String? fileUrl;
  final int? replyTo;
  final Map<String, dynamic>? replyToMessage;
  final Map<String, dynamic>? sender;
  final List<dynamic> reads;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.body,
    this.fileUrl,
    this.replyTo,
    this.replyToMessage,
    this.sender,
    this.reads = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageType: json['message_type'] ?? 'text',
      body: json['body'],
      fileUrl: json['file_url'],
      replyTo: json['reply_to'],
      replyToMessage: json['reply_to_message'],
      sender: json['sender'],
      reads: json['reads'] ?? [],
      createdAt: json['created_at'],
    );
  }
}

class ChatState {
  final List<ConversationModel> conversations;
  final Map<int, List<MessageModel>> messagesByConversation;
  final Map<int, String?> nextCursorByConversation;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.nextCursorByConversation = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    Map<int, List<MessageModel>>? messagesByConversation,
    Map<int, String?>? nextCursorByConversation,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messagesByConversation: messagesByConversation ?? this.messagesByConversation,
      nextCursorByConversation: nextCursorByConversation ?? this.nextCursorByConversation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _apiClient;

  ChatNotifier(this._apiClient) : super(const ChatState());

  Future<void> sendMessage(int conversationId, String text, {String type = 'text', int? replyTo}) async {
    try {
      final data = <String, dynamic>{
        'message_type': type,
        'body': text,
      };
      if (replyTo != null) {
        data['reply_to'] = replyTo;
      }
      
      // Show loading indicator/local feedback
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Trigger haptic feedback for sending message
      HapticFeedback.lightImpact();
      
      final response = await _apiClient.post(
        '/conversations/$conversationId/messages',
        data: data,
      );

      if (response.data['success'] == true) {
        final newMessage = MessageModel.fromJson(response.data['data']);
        
        // Append locally
        _appendMessage(conversationId, newMessage);
        
        // Show success feedback (animation + sound)
        await _showMessageSentFeedback(conversationId, newMessage);
        
        // Show local notification for new message
        await _showNewMessageNotification(conversationId, newMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      // Show error feedback
      _showMessageErrorFeedback();
    }
  }

  Future<void> _showMessageSentFeedback(int conversationId, MessageModel message) async {
    try {
      // Animate the message bubble with a "sent" animation
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Update conversation last message with sent status
      final newConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return ConversationModel(
            id: c.id,
            name: c.name,
            description: c.description,
            type: c.type,
            createdBy: c.createdBy,
            avatar: c.avatar,
            lastMessage: {
              'body': message.body,
              'created_at': message.createdAt,
              'status': 'sent',
            },
            members: c.members,
          );
        }
        return c;
      }).toList();
      
      state = state.copyWith(
        conversations: newConversations,
        isLoading: false,
      );
      
      // Trigger animation for the message bubble
      _triggerMessageAnimation(conversationId);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _showMessageErrorFeedback() async {
    try {
      // Show a snackbar or toast indicating the message sending failed
      // In a real app, this would show a Snackbar with retry option
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reset loading state
      state = state.copyWith(isLoading: false);
    } catch (_) {}
  }

  void _triggerMessageAnimation(int conversationId) {
    // In a real app, this would trigger animation library
    // For now, we'll just update the state to trigger a rebuild
    state = state.copyWith(isLoading: true);
    // Force rebuild to trigger animation
    state = state.copyWith(isLoading: false);
  }

  Future<void> _showNewMessageNotification(int conversationId, MessageModel message) async {
    try {
      await _apiClient.post('/notifications', data: {
        'type': 'message',
        'conversation_id': conversationId,
        'message_id': message.id,
        'title': 'Pesan baru',
        'body': message.body ?? 'Mengirim file',
      });
    } catch (_) {}
  }

  Future<void> loadConversations() async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await _apiClient.get('/conversations');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        state = state.copyWith(
          conversations: data.map((e) => ConversationModel.fromJson(e)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMessages(int conversationId) async {
    try {
      final current = Map<int, List<MessageModel>>.from(state.messagesByConversation);
      current[conversationId] = [];
      state = state.copyWith(messagesByConversation: current);
      final response = await _apiClient.get('/conversations/$conversationId/messages');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final messages = data.map((e) => MessageModel.fromJson(e)).toList();
        final newMap = Map<int, List<MessageModel>>.from(state.messagesByConversation);
        newMap[conversationId] = messages;
        state = state.copyWith(messagesByConversation: newMap);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> startConversation(int targetUserId) async {
    try {
      final response = await _apiClient.post('/conversations', data: {
        'type': 'direct',
        'target_user_id': targetUserId,
      });

      if (response.data['success'] == true) {
        // Refresh conversations list
        await loadConversations();
      }
    } catch (_) {}
  }

  Future<bool> inviteUser(int conversationId, int userId) async {
    try {
      final response = await _apiClient.post(
        '/conversations/$conversationId/invite',
        data: {'user_id': userId},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leaveConversation(int conversationId) async {
    try {
      final response = await _apiClient.post(
        '/conversations/$conversationId/leave',
      );
      if (response.data['success'] == true) {
        state = state.copyWith(
          conversations: state.conversations
              .where((c) => c.id != conversationId)
              .toList(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> destroyConversation(int conversationId) async {
    try {
      final response = await _apiClient.delete(
        '/conversations/$conversationId',
      );
      if (response.data['success'] == true) {
        state = state.copyWith(
          conversations: state.conversations
              .where((c) => c.id != conversationId)
              .toList(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> respondInvitation(int invitationId, String action) async {
    try {
      final response = await _apiClient.post(
        '/invitations/$invitationId/respond',
        data: {'action': action},
      );
      if (response.data['success'] == true) {
        await loadConversations();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(int conversationId, int messageId) async {
    try {
      final response = await _apiClient.delete('/messages/$messageId');
      if (response.data['success'] == true) {
        final newMessages = Map<int, List<MessageModel>>.from(state.messagesByConversation);
        final list = newMessages[conversationId] != null
            ? List<MessageModel>.from(newMessages[conversationId]!)
            : <MessageModel>[];
        list.removeWhere((m) => m.id == messageId);
        newMessages[conversationId] = list;
        state = state.copyWith(messagesByConversation: newMessages);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markAllAsRead(int conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/read-all');
    } catch (_) {}
  }

  // Handle incoming socket message locally
  void handleIncomingMessage(int conversationId, Map<String, dynamic> messageJson) {
    final message = MessageModel.fromJson(messageJson);
    _appendMessage(conversationId, message);
  }

  void _appendMessage(int conversationId, MessageModel message) {
    final newMessages = Map<int, List<MessageModel>>.from(state.messagesByConversation);
    final list = newMessages[conversationId] != null
        ? List<MessageModel>.from(newMessages[conversationId]!)
        : <MessageModel>[];
    
    // Avoid duplicates
    if (!list.any((m) => m.id == message.id)) {
      list.insert(0, message); // latest first
      newMessages[conversationId] = list;

      // Update last message in conversation list
      final newConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return ConversationModel(
            id: c.id,
            name: c.name,
            description: c.description,
            type: c.type,
            createdBy: c.createdBy,
            avatar: c.avatar,
            lastMessage: {
              'body': message.body,
              'created_at': message.createdAt,
            },
            members: c.members,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        messagesByConversation: newMessages,
        conversations: newConversations,
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return ChatNotifier(apiClient);
});
