import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

class MembershipConverter extends TypeConverter<Membership?, String?> {
  @override
  Membership? fromSql(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    try {
      final json = jsonDecode(fromDb) as Map<String, dynamic>;
      return Membership.fromJson(json);
    } catch (error, stackTrace) {
      e('failed to decode membership', error, stackTrace);
      return null;
    }
  }

  @override
  String? toSql(Membership? value) {
    if (value == null) {
      return null;
    }
    return jsonEncode(value.toJson());
  }
}
