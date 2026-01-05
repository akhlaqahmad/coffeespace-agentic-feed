import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'author.freezed.dart';
part 'author.g.dart';

@freezed
class Author with _$Author {
  const factory Author({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) = _Author;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
}

/// Manual Hive adapter for Author (Freezed classes don't work with hive_generator).
class AuthorAdapter extends TypeAdapter<Author> {
  @override
  final int typeId = 2;

  @override
  Author read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Author.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Author obj) {
    writer.writeMap(obj.toJson());
  }
}
