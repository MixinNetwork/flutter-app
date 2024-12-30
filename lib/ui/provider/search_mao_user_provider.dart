import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/dao/user_dao.dart';
import '../../db/mixin_database.dart';
import 'account_server_provider.dart';
import 'database_provider.dart';

class MaoUser with EquatableMixin {
  MaoUser({required this.user, required this.mao});

  final User user;
  final String mao;

  @override
  List<Object?> get props => [user, mao];
}

final searchMaoUserProvider =
    FutureProvider.autoDispose.family<MaoUser?, String>((ref, keyword) async {
  final client = ref.read(accountServerProvider).valueOrNull?.client;
  if (client == null) {
    return null;
  }
  if (keyword.isEmpty || !keyword.isValidMao()) {
    return null;
  }
  try {
    final user = (await client.userApi.search(keyword)).data.asDbUser;
    await ref.read(databaseProvider).valueOrNull?.userDao.insert(user);
    return MaoUser(user: user, mao: keyword.completeMao());
  } catch (error, stackTrace) {
    e('searchMaoUserProvider error: $error, $stackTrace');
    return null;
  }
});

extension StringExtension on String {
  String completeMao() {
    if (isMao()) {
      return this;
    } else {
      if (endsWith('.mao')) {
        return this;
      } else if (endsWith('.')) {
        return '${this}mao';
      } else if (endsWith('.m')) {
        return '${this}ao';
      } else if (endsWith('.ma')) {
        return '${this}o';
      } else {
        return '$this.mao';
      }
    }
  }

  bool isValidMao() {
    if (trim().isEmpty) return false;
    final text = trim().replaceAll(RegExp(r'\.$'), '');
    if (text.runes.every((r) => r >= 48 && r <= 57)) return false;
    final regex = RegExp(r'^[^\sA-Z]{1,128}$');
    return regex.hasMatch(text);
  }

  bool isMao() {
    final regex = RegExp(r'^[^\sA-Z]{1,128}\.mao$');
    return regex.hasMatch(this);
  }
}
