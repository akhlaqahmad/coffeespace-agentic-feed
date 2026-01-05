import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
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

/// Manual Hive adapter for Post (Freezed classes don't work with hive_generator).
class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 0;

  @override
  Post read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Post.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer.writeMap(obj.toJson());
  }
}
