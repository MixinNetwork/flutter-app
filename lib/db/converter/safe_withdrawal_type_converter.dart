import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

class SafeWithdrawalTypeConverter
    extends TypeConverter<SafeWithdrawal?, String?> {
  const SafeWithdrawalTypeConverter();

  @override
  SafeWithdrawal? fromSql(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    try {
      final json = jsonDecode(fromDb) as Map<String, dynamic>;
      return SafeWithdrawal.fromJson(json);
    } catch (error, stackTrace) {
      e('failed to decode safe withdrawal', error, stackTrace);
      return null;
    }
  }

  @override
  String? toSql(SafeWithdrawal? value) {
    if (value == null) {
      return null;
    }
    return jsonEncode(value.toJson());
  }
}
