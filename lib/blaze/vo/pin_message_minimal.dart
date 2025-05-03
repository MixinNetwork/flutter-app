import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pin_message_minimal.g.dart';

@JsonSerializable()
class PinMessageMinimal extends Equatable {
  const PinMessageMinimal({
    required this.messageId,
    required this.type,
    required this.content,
  });

  factory PinMessageMinimal.fromJson(Map<String, dynamic> json) =>
      _$PinMessageMinimalFromJson(json);

  static PinMessageMinimal? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return _$PinMessageMinimalFromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'category')
  final String type;
  final String? content;

  Map<String, dynamic> toJson() => _$PinMessageMinimalToJson(this);

  @override
  List<Object?> get props => [messageId, type, content];
}
