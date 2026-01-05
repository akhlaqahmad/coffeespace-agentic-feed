import 'package:freezed_annotation/freezed_annotation.dart';
import 'author.dart';
import 'optimistic_state.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required Author author,
    required String content,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default(0) int repostCount,
    @Default(0) int replyCount,
    @Default(false) bool isLiked,
    @Default(false) bool isReposted,
    OptimisticState? optimisticState,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

