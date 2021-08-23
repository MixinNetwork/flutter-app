import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transcript_minimal.g.dart';

@JsonSerializable()
class TranscriptMinimal extends Equatable {
  const TranscriptMinimal({
    required this.name,
    required this.category,
    this.content,
  });

  factory TranscriptMinimal.fromJson(Map<String, dynamic> json) =>
      _$TranscriptMinimalFromJson(json);

  final String name;
  final String category;
  final String? content;

  Map<String, dynamic> toJson() => _$TranscriptMinimalToJson(this);

  @override
  List<Object?> get props => [name, category, content];
}
