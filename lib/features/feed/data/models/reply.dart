import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
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

/// Manual Hive adapter for Reply (Freezed classes don't work with hive_generator).
class ReplyAdapter extends TypeAdapter<Reply> {
  @override
  final int typeId = 1;

  @override
  Reply read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Reply.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Reply obj) {
    writer.writeMap(obj.toJson());
  }
}
