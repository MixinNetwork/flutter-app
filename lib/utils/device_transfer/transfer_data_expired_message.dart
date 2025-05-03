import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_expired_message.g.dart';

@JsonSerializable()
class TransferDataExpiredMessage {
  TransferDataExpiredMessage({
    required this.messageId,
    required this.expireIn,
    this.expireAt,
  });

  factory TransferDataExpiredMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferDataExpiredMessageFromJson(json);

  factory TransferDataExpiredMessage.fromDbExpiredMessage(
    db.ExpiredMessage expiredMessage,
  ) => TransferDataExpiredMessage(
    messageId: expiredMessage.messageId,
    expireIn: expiredMessage.expireIn,
    expireAt: expiredMessage.expireAt,
  );

  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'expire_in')
  final int expireIn;

  @JsonKey(name: 'expire_at')
  final int? expireAt;

  db.ExpiredMessage toDbExpiredMessage() => db.ExpiredMessage(
    messageId: messageId,
    expireIn: expireIn,
    expireAt: expireAt,
  );

  Map<String, dynamic> toJson() => _$TransferDataExpiredMessageToJson(this);
}
