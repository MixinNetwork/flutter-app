// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataParticipant _$TransferDataParticipantFromJson(
        Map<String, dynamic> json) =>
    TransferDataParticipant(
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      role: const ParticipantRoleJsonConverter()
          .fromJson(json['role'] as String?),
    );

Map<String, dynamic> _$TransferDataParticipantToJson(
        TransferDataParticipant instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'role': const ParticipantRoleJsonConverter().toJson(instance.role),
      'created_at': instance.createdAt.toIso8601String(),
    };
