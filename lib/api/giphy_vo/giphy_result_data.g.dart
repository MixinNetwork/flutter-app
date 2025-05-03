// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'giphy_result_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GiphyResultData _$GiphyResultDataFromJson(Map<String, dynamic> json) =>
    GiphyResultData(
      (json['data'] as List<dynamic>)
          .map((e) => GiphyGif.fromJson(e as Map<String, dynamic>))
          .toList(),
      Meta.fromJson(json['meta'] as Map<String, dynamic>),
      Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GiphyResultDataToJson(GiphyResultData instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
      'pagination': instance.pagination.toJson(),
    };

Meta _$MetaFromJson(Map<String, dynamic> json) => Meta(
  (json['status'] as num).toInt(),
  json['msg'] as String,
  json['response_id'] as String,
);

Map<String, dynamic> _$MetaToJson(Meta instance) => <String, dynamic>{
  'status': instance.status,
  'msg': instance.msg,
  'response_id': instance.responseId,
};

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  (json['total_count'] as num).toInt(),
  (json['count'] as num).toInt(),
  (json['offset'] as num).toInt(),
);

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'total_count': instance.totalCount,
      'count': instance.count,
      'offset': instance.offset,
    };
