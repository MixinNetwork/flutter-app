import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

class SafeDepositTypeConverter extends TypeConverter<SafeDeposit?, String?> {
  const SafeDepositTypeConverter();

  @override
  SafeDeposit? fromSql(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    try {
      final json = jsonDecode(fromDb) as Map<String, dynamic>;
      return SafeDeposit.fromJson(json);
    } catch (error, stackTrace) {
      e('failed to decode safe deposit', error, stackTrace);
      return null;
    }
  }

  @override
  String? toSql(SafeDeposit? value) {
    if (value == null) {
      return null;
    }
    return jsonEncode(value.toJson());
  }
}
