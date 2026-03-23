import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../account/account_server.dart';
import '../../runtime/app_runtime_hub.dart';

final appRuntimeHubProvider =
    NotifierProvider.autoDispose<AppRuntimeHub, AppRuntimeState>(
      AppRuntimeHub.new,
    );

final accountServerProvider = Provider.autoDispose<AsyncValue<AccountServer>>(
  (ref) =>
      ref.watch(appRuntimeHubProvider.select((value) => value.accountServer)),
);
