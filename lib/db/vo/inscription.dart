import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inscription.g.dart';

@JsonSerializable()
class Inscription with EquatableMixin {
  Inscription({
    required this.collectionHash,
    required this.inscriptionHash,
    required this.sequence,
    required this.contentType,
    required this.contentUrl,
    this.name,
    this.iconUrl,
  });

  factory Inscription.fromJson(Map<String, dynamic> json) =>
      _$InscriptionFromJson(json);

  @JsonKey(name: 'collection_hash')
  final String collectionHash;
  @JsonKey(name: 'inscription_hash')
  final String inscriptionHash;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'sequence')
  final int sequence;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'content_url')
  final String contentUrl;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;

  Map<String, dynamic> toJson() => _$InscriptionToJson(this);

  @override
  List<Object?> get props => [
    collectionHash,
    inscriptionHash,
    name,
    sequence,
    contentType,
    contentUrl,
    iconUrl,
  ];
}
