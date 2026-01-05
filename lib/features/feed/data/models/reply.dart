import 'package:freezed_annotation/freezed_annotation.dart';
import 'author.dart';
import 'optimistic_state.dart';

part 'reply.freezed.dart';
part 'reply.g.dart';

@freezed
class Reply with _$Reply {
  const factory Reply({
    required String id,
    required String postId,
    required Author author,
    required String content,
    required DateTime createdAt,
    OptimisticState? optimisticState,
  }) = _Reply;

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
}

