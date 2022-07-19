import 'package:json_annotation/json_annotation.dart';

import 'giphy_gif.dart';

part 'giphy_result_data.g.dart';

@JsonSerializable()
class GiphyResultData {
  GiphyResultData(this.data, this.meta, this.pagination);

  factory GiphyResultData.fromJson(Map<String, dynamic> json) =>
      _$GiphyResultDataFromJson(json);

  @JsonKey(name: 'data')
  final List<GiphyGif> data;
  final Meta meta;
  final Pagination pagination;

  Map<String, dynamic> toJson() => _$GiphyResultDataToJson(this);
}

@JsonSerializable()
class Meta {
  Meta(this.status, this.msg, this.responseId);

  factory Meta.fromJson(Map<String, dynamic> json) => _$MetaFromJson(json);

  final int status;
  final String msg;

  @JsonKey(name: 'response_id')
  final String responseId;

  Map<String, dynamic> toJson() => _$MetaToJson(this);
}

@JsonSerializable()
class Pagination {
  Pagination(this.totalCount, this.count, this.offset);

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  @JsonKey(name: 'total_count')
  final int totalCount;
  final int count;
  final int offset;

  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
