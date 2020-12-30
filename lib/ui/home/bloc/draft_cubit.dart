import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

// conversation id : draft
class DraftCubit extends Cubit<Map<String, String>> {
  DraftCubit() : super({});

  final BlockTextEditingController textEditingController =
      BlockTextEditingController();

  void update(String name) {
    final text = textEditingController.text;
    state[name] = text.isEmpty ?? true ? null : text;
    emit(state);
  }

  void show(String name) {
    final text = state[name] ?? '';
    textEditingController
      ..text = text
      ..selection = TextSelection.fromPosition(
        TextPosition(
          affinity: TextAffinity.downstream,
          offset: text.length,
        ),
      );
  }
}

class BlockTextEditingController extends TextEditingController {
  BlockTextEditingController();

  bool block = false;

  @override
  set value(TextEditingValue newValue) {
    if (block) return;
    super.value = newValue;
  }
}
