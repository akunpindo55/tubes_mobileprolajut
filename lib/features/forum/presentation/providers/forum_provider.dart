import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ForumModel {
  final int id;
  final String name;
  final String? description;
  final bool isPrivate;
  final int createdBy;
  final String createdAt;

  ForumModel({
    required this.id,
    required this.name,
    this.description,
    required this.isPrivate,
    required this.createdBy,
    required this.createdAt,
  });

  factory ForumModel.fromJson(Map<String, dynamic> json) {
    return ForumModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isPrivate: json['is_private'] == true || json['is_private'] == 1,
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TopicModel {
  final int id;
  final int forumId;
  final String title;
  final String content;
  final int userId;
  final Map<String, dynamic> user;
  final String createdAt;
  final List<ForumCommentModel>? comments;

  TopicModel({
    required this.id,
    required this.forumId,
    required this.title,
    required this.content,
    required this.userId,
    required this.user,
    required this.createdAt,
    this.comments,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : <String, dynamic>{};
    var rawComments = json['comments'] as List?;
    List<ForumCommentModel>? commentList;
    if (rawComments != null) {
      commentList = rawComments.map((c) => ForumCommentModel.fromJson(c)).toList();
    }
    return TopicModel(
      id: json['id'],
      forumId: json['forum_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      userId: userData['id'] as int? ?? json['user_id'] as int? ?? 0,
      user: userData,
      createdAt: json['created_at'] ?? '',
      comments: commentList,
    );
  }
}

class ForumCommentModel {
  final int id;
  final int topicId;
  final int userId;
  final Map<String, dynamic> user;
  final String content;
  final int? parentCommentId;
  final List<ForumCommentModel> replies;
  final String createdAt;

  ForumCommentModel({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.user,
    required this.content,
    this.parentCommentId,
    required this.replies,
    required this.createdAt,
  });

  factory ForumCommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : <String, dynamic>{};
    var rawReplies = json['replies'] as List?;
    List<ForumCommentModel> replyList = [];
    if (rawReplies != null) {
      replyList = rawReplies.map((r) => ForumCommentModel.fromJson(r)).toList();
    }
    return ForumCommentModel(
      id: json['id'],
      topicId: json['topic_id'] ?? 0,
      userId: userData['id'] as int? ?? json['user_id'] as int? ?? 0,
      user: userData,
      content: json['content'] ?? '',
      parentCommentId: json['parent_comment_id'],
      replies: replyList,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ForumState {
  final List<ForumModel> publicForums;
  final List<ForumModel> myForums;
  final Map<int, List<TopicModel>> topicsByForum;
  final Map<int, TopicModel> topicDetails;
  final bool isLoading;
  final String? errorMessage;

  const ForumState({
    this.publicForums = const [],
    this.myForums = const [],
    this.topicsByForum = const {},
    this.topicDetails = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  ForumState copyWith({
    List<ForumModel>? publicForums,
    List<ForumModel>? myForums,
    Map<int, List<TopicModel>>? topicsByForum,
    Map<int, TopicModel>? topicDetails,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ForumState(
      publicForums: publicForums ?? this.publicForums,
      myForums: myForums ?? this.myForums,
      topicsByForum: topicsByForum ?? this.topicsByForum,
      topicDetails: topicDetails ?? this.topicDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ForumNotifier extends StateNotifier<ForumState> {
  final ApiClient _apiClient;

  ForumNotifier(this._apiClient) : super(const ForumState());

  Future<void> loadPublicForums() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/forums');
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((json) => ForumModel.fromJson(json))
            .toList();
        state = state.copyWith(publicForums: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMyForums() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/forums/my');
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((json) => ForumModel.fromJson(json))
            .toList();
        state = state.copyWith(myForums: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createForum(String name, String? description, bool isPrivate) async {
    try {
      final response = await _apiClient.post('/forums', data: {
        'name': name,
        'description': description,
        'is_private': isPrivate,
      });

      if (response.data['success'] == true) {
        final newForum = ForumModel.fromJson(response.data['data']);
        state = state.copyWith(
          myForums: [...state.myForums, newForum],
          publicForums: isPrivate ? state.publicForums : [...state.publicForums, newForum],
        );
        return true;
      }
      print('[createForum] API error: ${response.data}');
      return false;
    } catch (e) {
      print('[createForum] exception: $e');
      return false;
    }
  }

  Future<bool> joinForum(int forumId) async {
    try {
      final response = await _apiClient.post('/forums/$forumId/join');
      if (response.data['success'] == true) {
        // Refresh My Forums list
        await loadMyForums();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leaveForum(int forumId) async {
    try {
      final response = await _apiClient.post('/forums/$forumId/leave');
      if (response.data['success'] == true) {
        state = state.copyWith(
          myForums: state.myForums.where((f) => f.id != forumId).toList(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadTopics(int forumId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/forums/$forumId/topics');
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((json) => TopicModel.fromJson(json))
            .toList();

        final newTopicsMap = Map<int, List<TopicModel>>.from(state.topicsByForum);
        newTopicsMap[forumId] = list;

        state = state.copyWith(
          topicsByForum: newTopicsMap,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createTopic(int forumId, String title, String content) async {
    try {
      final response = await _apiClient.post('/forums/$forumId/topics', data: {
        'title': title,
        'content': content,
      });

      if (response.data['success'] == true) {
        final newTopic = TopicModel.fromJson(response.data['data']);
        
        final newTopicsMap = Map<int, List<TopicModel>>.from(state.topicsByForum);
        final list = newTopicsMap[forumId] != null
            ? List<TopicModel>.from(newTopicsMap[forumId]!)
            : <TopicModel>[];
        list.insert(0, newTopic);
        newTopicsMap[forumId] = list;

        state = state.copyWith(topicsByForum: newTopicsMap);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadTopicDetail(int topicId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/topics/$topicId');
      if (response.data['success'] == true) {
        final topicObj = TopicModel.fromJson(response.data['data']);
        
        final newDetails = Map<int, TopicModel>.from(state.topicDetails);
        newDetails[topicId] = topicObj;

        state = state.copyWith(
          topicDetails: newDetails,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> inviteMember(int forumId, int userId) async {
    try {
      final response = await _apiClient.post(
        '/forums/$forumId/invite',
        data: {'user_id': userId},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> kickMember(int forumId, int memberId) async {
    try {
      final response = await _apiClient.post(
        '/forums/$forumId/kick/$memberId',
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> respondForumInvitation(int invitationId, String action) async {
    try {
      final response = await _apiClient.post(
        '/forum-invitations/$invitationId/respond',
        data: {'action': action},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTopic(int topicId) async {
    try {
      final response = await _apiClient.delete('/topics/$topicId');
      if (response.data['success'] == true) {
        final newTopicsByForum = Map<int, List<TopicModel>>.from(state.topicsByForum);
        for (final forumId in newTopicsByForum.keys) {
          newTopicsByForum[forumId] = newTopicsByForum[forumId]!
              .where((t) => t.id != topicId)
              .toList();
        }
        final newDetails = Map<int, TopicModel>.from(state.topicDetails);
        newDetails.remove(topicId);
        state = state.copyWith(
          topicsByForum: newTopicsByForum,
          topicDetails: newDetails,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _apiClient.delete('/comments/$commentId');
      if (response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> replyTopic(int topicId, String commentContent, {int? parentCommentId}) async {
    try {
      final response = await _apiClient.post('/topics/$topicId/comments', data: {
        'content': commentContent,
        // ignore: use_null_aware_elements
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      });

      if (response.data['success'] == true) {
        // Refresh topic detail to load the latest replies hierarchy correctly
        await loadTopicDetail(topicId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final forumProvider = StateNotifierProvider<ForumNotifier, ForumState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return ForumNotifier(apiClient);
});
