import 'package:json_annotation/json_annotation.dart';

import '../../db/extension/app.dart';
import '../../db/mixin_database.dart' as db;

part 'transfer_data_app.g.dart';

@JsonSerializable()
class TransferDataApp {
  TransferDataApp({
    required this.appId,
    required this.appNumber,
    required this.homeUri,
    required this.redirectUri,
    required this.name,
    required this.iconUrl,
    required this.category,
    required this.description,
    required this.appSecret,
    required this.capabilities,
    required this.creatorId,
    required this.resourcePatterns,
    required this.updatedAt,
  });

  factory TransferDataApp.fromJson(Map<String, dynamic> json) =>
      _$TransferDataAppFromJson(json);

  factory TransferDataApp.fromDbApp(db.App a) => TransferDataApp(
    appId: a.appId,
    appNumber: a.appNumber,
    homeUri: a.homeUri,
    redirectUri: a.redirectUri,
    name: a.name,
    iconUrl: a.iconUrl,
    category: a.category,
    description: a.description,
    appSecret: a.appSecret,
    capabilities: a.capabilitiesList,
    creatorId: a.creatorId,
    resourcePatterns: a.resourcePatternsList,
    updatedAt: a.updatedAt,
  );

  @JsonKey(name: 'app_id')
  final String appId;
  @JsonKey(name: 'app_number')
  final String appNumber;
  @JsonKey(name: 'home_uri')
  final String homeUri;
  @JsonKey(name: 'redirect_uri')
  final String redirectUri;
  final String name;
  @JsonKey(name: 'icon_url')
  final String iconUrl;
  final String? category;
  final String description;
  @JsonKey(name: 'app_secret')
  final String appSecret;
  @JsonKey(name: 'capabilities')
  final List<String>? capabilities;
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'resource_patterns')
  final List<String>? resourcePatterns;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$TransferDataAppToJson(this);

  db.App toDbApp() => db.App(
    appId: appId,
    appNumber: appNumber,
    homeUri: homeUri,
    redirectUri: redirectUri,
    name: name,
    iconUrl: iconUrl,
    category: category,
    description: description,
    appSecret: appSecret,
    capabilities: capabilities?.toString(),
    creatorId: creatorId,
    resourcePatterns: resourcePatterns?.toString(),
    updatedAt: updatedAt,
  );
}
