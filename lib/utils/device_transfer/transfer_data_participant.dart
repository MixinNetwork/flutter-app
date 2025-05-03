import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_participant.g.dart';

@JsonSerializable()
@ParticipantRoleJsonConverter()
class TransferDataParticipant {
  TransferDataParticipant({
    required this.conversationId,
    required this.userId,
    required this.createdAt,
    this.role,
  });

  factory TransferDataParticipant.fromJson(Map<String, dynamic> json) =>
      _$TransferDataParticipantFromJson(json);

  factory TransferDataParticipant.fromDbParticipant(
    db.Participant participant,
  ) => TransferDataParticipant(
    conversationId: participant.conversationId,
    userId: participant.userId,
    role: participant.role,
    createdAt: participant.createdAt,
  );

  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'role')
  final ParticipantRole? role;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  db.Participant toDbParticipant() => db.Participant(
    conversationId: conversationId,
    userId: userId,
    role: role,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => _$TransferDataParticipantToJson(this);
}
