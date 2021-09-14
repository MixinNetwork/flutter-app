import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class ShowPinMessageKeyValue extends HiveKeyValue<bool> {
  ShowPinMessageKeyValue._() : super(_hiveName);

  static const _hiveName = 'show_pin_message_box';

  static ShowPinMessageKeyValue? _instance;

  static ShowPinMessageKeyValue get instance =>
      _instance ??= ShowPinMessageKeyValue._();

  Future<void> show(String conversationId) => box.put(conversationId, true);

  bool isShow(String conversationId) =>
      box.get(conversationId, defaultValue: true)!;

  Future<void> dismiss(String conversationId) => box.put(conversationId, false);

  Stream<bool> watch(String conversationId) => box
      .watch(key: conversationId)
      .map((event) => event.value ?? true)
      .where((event) => event is bool)
      .cast<bool>()
      .startWith(isShow(conversationId));
}
