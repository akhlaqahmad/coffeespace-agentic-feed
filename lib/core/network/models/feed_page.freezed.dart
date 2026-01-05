// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeedPage _$FeedPageFromJson(Map<String, dynamic> json) {
  return _FeedPage.fromJson(json);
}

/// @nodoc
mixin _$FeedPage {
  @JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
  List<Post> get posts => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeedPageCopyWith<FeedPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedPageCopyWith<$Res> {
  factory $FeedPageCopyWith(FeedPage value, $Res Function(FeedPage) then) =
      _$FeedPageCopyWithImpl<$Res, FeedPage>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
      List<Post> posts,
      String? nextCursor});
}

/// @nodoc
class _$FeedPageCopyWithImpl<$Res, $Val extends FeedPage>
    implements $FeedPageCopyWith<$Res> {
  _$FeedPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? nextCursor = freezed,
  }) {
    return _then(_value.copyWith(
      posts: null == posts
          ? _value.posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<Post>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedPageImplCopyWith<$Res>
    implements $FeedPageCopyWith<$Res> {
  factory _$$FeedPageImplCopyWith(
          _$FeedPageImpl value, $Res Function(_$FeedPageImpl) then) =
      __$$FeedPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
      List<Post> posts,
      String? nextCursor});
}

/// @nodoc
class __$$FeedPageImplCopyWithImpl<$Res>
    extends _$FeedPageCopyWithImpl<$Res, _$FeedPageImpl>
    implements _$$FeedPageImplCopyWith<$Res> {
  __$$FeedPageImplCopyWithImpl(
      _$FeedPageImpl _value, $Res Function(_$FeedPageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? nextCursor = freezed,
  }) {
    return _then(_$FeedPageImpl(
      posts: null == posts
          ? _value._posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<Post>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedPageImpl implements _FeedPage {
  const _$FeedPageImpl(
      {@JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
      required final List<Post> posts,
      this.nextCursor})
      : _posts = posts;

  factory _$FeedPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedPageImplFromJson(json);

  final List<Post> _posts;
  @override
  @JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
  List<Post> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  @override
  final String? nextCursor;

  @override
  String toString() {
    return 'FeedPage(posts: $posts, nextCursor: $nextCursor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedPageImpl &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_posts), nextCursor);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedPageImplCopyWith<_$FeedPageImpl> get copyWith =>
      __$$FeedPageImplCopyWithImpl<_$FeedPageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedPageImplToJson(
      this,
    );
  }
}

abstract class _FeedPage implements FeedPage {
  const factory _FeedPage(
      {@JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
      required final List<Post> posts,
      final String? nextCursor}) = _$FeedPageImpl;

  factory _FeedPage.fromJson(Map<String, dynamic> json) =
      _$FeedPageImpl.fromJson;

  @override
  @JsonKey(fromJson: _postsFromJson, toJson: _postsToJson)
  List<Post> get posts;
  @override
  String? get nextCursor;
  @override
  @JsonKey(ignore: true)
  _$$FeedPageImplCopyWith<_$FeedPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
