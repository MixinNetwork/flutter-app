import '../hive_key_values.dart';

class DownloadKeyValue extends HiveKeyValue<String> {
  DownloadKeyValue() : super(_hiveName);

  static const _hiveName = 'download_box';

  Iterable<String> get messageIds => box.values;

  Future<void> addMessageId(String messageId) => box.put(messageId, messageId);

  Future<void> removeMessageId(String messageId) => box.delete(messageId);

}
