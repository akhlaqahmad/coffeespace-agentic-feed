// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
      id: json['id'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      repostCount: (json['repostCount'] as num?)?.toInt() ?? 0,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isReposted: json['isReposted'] as bool? ?? false,
      optimisticState: $enumDecodeNullable(
          _$OptimisticStateEnumMap, json['optimisticState']),
    );

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'repostCount': instance.repostCount,
      'replyCount': instance.replyCount,
      'isLiked': instance.isLiked,
      'isReposted': instance.isReposted,
      'optimisticState': _$OptimisticStateEnumMap[instance.optimisticState],
    };

const _$OptimisticStateEnumMap = {
  OptimisticState.pending: 'pending',
  OptimisticState.failed: 'failed',
  OptimisticState.confirmed: 'confirmed',
};
