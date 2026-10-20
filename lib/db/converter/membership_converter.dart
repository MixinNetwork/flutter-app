import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

// Each query decodes the membership of every user row again, and its date
// parse is costly, so the decoded value is kept per stored text.
final _decoded = <String, Membership?>{};

class MembershipConverter extends TypeConverter<Membership?, String?> {
  const MembershipConverter();

  @override
  Membership? fromSql(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    if (_decoded.length >= 1024) _decoded.clear();
    return _decoded.putIfAbsent(fromDb, () => _decode(fromDb));
  }

  Membership? _decode(String fromDb) {
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
