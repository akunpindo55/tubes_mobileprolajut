import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PostModel {
  final int id;
  final Map<String, dynamic> user;
  final String content;
  final String visibility;
  final List<dynamic> media;
  final int commentsCount;
  final Map<String, dynamic> reactionsSummary;
  final int reactionsTotal;
  final String? userReaction;
  final String createdAt;

  PostModel({
    required this.id,
    required this.user,
    required this.content,
    required this.visibility,
    required this.media,
    required this.commentsCount,
    required this.reactionsSummary,
    required this.reactionsTotal,
    this.userReaction,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['reactions_summary'];
    return PostModel(
      id: json['id'],
      user: json['user'] ?? {},
      content: json['content'] ?? '',
      visibility: json['visibility'] ?? 'public',
      media: json['media'] ?? [],
      commentsCount: json['comments_count'] ?? 0,
      reactionsSummary: (rawSummary is Map) ? Map<String, dynamic>.from(rawSummary) : {},
      reactionsTotal: json['reactions_total'] ?? 0,
      userReaction: json['user_reaction'],
      createdAt: json['created_at'] ?? '',
    );
  }

  PostModel copyWith({
    int? commentsCount,
    Map<String, dynamic>? reactionsSummary,
    int? reactionsTotal,
    String? userReaction,
  }) {
    return PostModel(
      id: id,
      user: user,
      content: content,
      visibility: visibility,
      media: media,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsSummary: reactionsSummary ?? this.reactionsSummary,
      reactionsTotal: reactionsTotal ?? this.reactionsTotal,
      userReaction: userReaction,
      createdAt: createdAt,
    );
  }
}

class CommentModel {
  final int id;
  final int postId;
  final int userId;
  final String comment;
  final Map<String, dynamic> user;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.comment,
    required this.user,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : <String, dynamic>{};
    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      userId: userData['id'] as int? ?? json['user_id'] as int? ?? 0,
      comment: json['comment'] ?? '',
      user: userData,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FeedState {
  final List<PostModel> posts;
  final Map<int, List<CommentModel>> commentsByPost;
  final bool isLoading;
  final String? errorMessage;

  const FeedState({
    this.posts = const [],
    this.commentsByPost = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    Map<int, List<CommentModel>>? commentsByPost,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      commentsByPost: commentsByPost ?? this.commentsByPost,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ApiClient _apiClient;

  FeedNotifier(this._apiClient) : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/posts');
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((json) => PostModel.fromJson(json))
            .toList();
        state = state.copyWith(posts: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createPost(String content, {String visibility = 'public'}) async {
    try {
      final response = await _apiClient.post('/posts', data: {
        'content': content,
        'visibility': visibility == 'internal' ? 'private' : visibility,
      });

      if (response.data['success'] == true) {
        final newPost = PostModel.fromJson(response.data['data']);
        state = state.copyWith(
          posts: [newPost, ...state.posts],
        );
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('[createPost error] $e');
      return false;
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      final response = await _apiClient.delete('/posts/$postId');
      if (response.data['success'] == true) {
        state = state.copyWith(
          posts: state.posts.where((p) => p.id != postId).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> reactPost(int postId, String type) async {
    final oldPostIndex = state.posts.indexWhere((p) => p.id == postId);
    if (oldPostIndex == -1) return;

    final oldPost = state.posts[oldPostIndex];
    final String? currentReaction = oldPost.userReaction;

    String? newReaction;
    int reactionsDiff = 0;
    Map<String, dynamic> newSummary = Map<String, dynamic>.from(oldPost.reactionsSummary);

    if (currentReaction == type) {
      newReaction = null;
      reactionsDiff = -1;
      newSummary[type] = (newSummary[type] ?? 1) - 1;
      if (newSummary[type]! <= 0) {
        newSummary.remove(type);
      }
    } else {
      newReaction = type;
      if (currentReaction != null) {
        reactionsDiff = 0;
        newSummary[currentReaction] = (newSummary[currentReaction] ?? 1) - 1;
        if (newSummary[currentReaction]! <= 0) {
          newSummary.remove(currentReaction);
        }
      } else {
        reactionsDiff = 1;
      }
      newSummary[type] = (newSummary[type] ?? 0) + 1;
    }

    final updatedPost = oldPost.copyWith(
      userReaction: newReaction,
      reactionsTotal: oldPost.reactionsTotal + reactionsDiff,
      reactionsSummary: newSummary,
    );

    final updatedPosts = List<PostModel>.from(state.posts);
    updatedPosts[oldPostIndex] = updatedPost;
    state = state.copyWith(posts: updatedPosts);

    try {
      await _apiClient.post('/posts/$postId/reactions', data: {
        'reaction_type': type,
      });
    } catch (_) {
      await loadFeed();
    }
  }

  Future<void> loadComments(int postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId');
      if (response.data['success'] == true) {
        final rawComments = response.data['data']['latest_comments'] as List? ?? [];
        final comments = rawComments
            .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
            .toList();
        final newMap = Map<int, List<CommentModel>>.from(state.commentsByPost);
        newMap[postId] = comments;
        state = state.copyWith(commentsByPost: newMap);
      }
    } catch (_) {}
  }

  Future<bool> updatePost(int postId, String content, {String visibility = 'public'}) async {
    try {
      final response = await _apiClient.put('/posts/$postId', data: {
        'content': content,
        'visibility': visibility,
      });
      if (response.data['success'] == true) {
        final updatedPost = PostModel.fromJson(response.data['data']);
        state = state.copyWith(
          posts: state.posts.map((p) => p.id == postId ? updatedPost : p).toList(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePostComment(int postId, int commentId) async {
    try {
      final response = await _apiClient.delete('/posts/$postId/comments/$commentId');
      if (response.data['success'] == true) {
        final newCommentsByPost = Map<int, List<CommentModel>>.from(state.commentsByPost);
        final list = newCommentsByPost[postId] != null
            ? List<CommentModel>.from(newCommentsByPost[postId]!)
            : <CommentModel>[];
        list.removeWhere((c) => c.id == commentId);
        newCommentsByPost[postId] = list;

        final updatedPosts = state.posts.map((p) {
          if (p.id == postId) {
            return p.copyWith(commentsCount: p.commentsCount - 1);
          }
          return p;
        }).toList();

        state = state.copyWith(
          commentsByPost: newCommentsByPost,
          posts: updatedPosts,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addComment(int postId, String commentText) async {
    try {
      final response = await _apiClient.post('/posts/$postId/comments', data: {
        'comment': commentText,
      });

      if (response.data['success'] == true) {
        final commentObj = CommentModel.fromJson(response.data['data']);
        
        final newCommentsByPost = Map<int, List<CommentModel>>.from(state.commentsByPost);
        final list = newCommentsByPost[postId] != null 
            ? List<CommentModel>.from(newCommentsByPost[postId]!)
            : <CommentModel>[];
        list.add(commentObj);
        newCommentsByPost[postId] = list;

        final updatedPosts = state.posts.map((p) {
          if (p.id == postId) {
            return p.copyWith(commentsCount: p.commentsCount + 1);
          }
          return p;
        }).toList();

        state = state.copyWith(
          commentsByPost: newCommentsByPost,
          posts: updatedPosts,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final apiClient = ref.watch(apiProvider);
  return FeedNotifier(apiClient);
});
