// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReplyImpl _$$ReplyImplFromJson(Map<String, dynamic> json) => _$ReplyImpl(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      optimisticState: $enumDecodeNullable(
          _$OptimisticStateEnumMap, json['optimisticState']),
    );

Map<String, dynamic> _$$ReplyImplToJson(_$ReplyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'author': instance.author,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'optimisticState': _$OptimisticStateEnumMap[instance.optimisticState],
    };

const _$OptimisticStateEnumMap = {
  OptimisticState.pending: 'pending',
  OptimisticState.failed: 'failed',
  OptimisticState.confirmed: 'confirmed',
};
