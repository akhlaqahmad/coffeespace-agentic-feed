import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:coffeespace_agentic_feed/features/feed/data/models/post.dart';

part 'feed_page.freezed.dart';
part 'feed_page.g.dart';

@freezed
class FeedPage with _$FeedPage {
  const factory FeedPage({
    @JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
    required List<Post> posts,
    String? nextCursor,
  }) = _FeedPage;

  factory FeedPage.fromJson(Map<String, dynamic> json) =>
      _$FeedPageFromJson(json);
}

List<Post> _postsFromJson(List<dynamic> json) {
  return json.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
}

List<Map<String, dynamic>> _postsToJson(List<Post> posts) {
  return posts.map((e) => e.toJson()).toList();
}

