import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import 'account_server_provider.dart';

final tokenProvider = StreamProvider.autoDispose.family<Token?, String?>(
  (ref, assetId) {
    if (assetId == null) {
      return const Stream.empty();
    }
    final database = ref.read(accountServerProvider).requireValue.database;
    final stream =
        database.tokenDao.tokenById(assetId).watchSingleOrNullWithStream(
      eventStreams: [
        DataBaseEventBus.instance.updateTokenStream
            .where((event) => event.contains(assetId)),
      ],
      duration: kDefaultThrottleDuration,
    );
    return stream;
  },
);

final safeSnapshotProvider =
    StreamProvider.autoDispose.family<SafeSnapshot?, String?>(
  (ref, snapshotId) {
    if (snapshotId == null) {
      return const Stream.empty();
    }
    final database = ref.read(accountServerProvider).requireValue.database;
    final stream = database.safeSnapshotDao
        .safeSnapshotById(snapshotId)
        .watchSingleOrNullWithStream(
      eventStreams: [
        DataBaseEventBus.instance.updateSafeSnapshotStream
            .where((event) => event.contains(snapshotId)),
      ],
      duration: kDefaultThrottleDuration,
    );
    return stream;
  },
);
