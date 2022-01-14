import '../hive_key_values.dart';

class DownloadKeyValue extends HiveKeyValue<String> {
  DownloadKeyValue._() : super(_hiveName);

  static DownloadKeyValue? _instance;

  static DownloadKeyValue get instance => _instance ??= DownloadKeyValue._();

  static const _hiveName = 'download_box';

  Iterable<String> get messageIds => box.values;

  Future<void> addMessageId(String messageId) => box.put(messageId, messageId);

  Future<void> removeMessageId(String messageId) => box.delete(messageId);

  Future<int> clear() => box.clear();
}
