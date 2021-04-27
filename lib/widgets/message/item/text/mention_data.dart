import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mention_data.g.dart';

@JsonSerializable()
class MentionData extends Equatable {
  const MentionData(
    this.identityNumber,
    this.fullName,
  );

  factory MentionData.fromJson(Map<String, dynamic> json) =>
      _$MentionDataFromJson(json);

  @JsonKey(name: 'identity_number')
  final String identityNumber;
  @JsonKey(name: 'full_name')
  final String fullName;

  Map<String, dynamic> toJson() => _$MentionDataToJson(this);

  @override
  List<Object?> get props => [identityNumber, fullName];
}
