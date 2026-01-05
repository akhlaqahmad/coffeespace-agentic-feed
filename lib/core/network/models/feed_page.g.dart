// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedPageImpl _$$FeedPageImplFromJson(Map<String, dynamic> json) =>
    _$FeedPageImpl(
      posts: _postsFromJson(json['posts'] as List),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$$FeedPageImplToJson(_$FeedPageImpl instance) =>
    <String, dynamic>{
      'posts': _postsToJson(instance.posts),
      'nextCursor': instance.nextCursor,
    };
