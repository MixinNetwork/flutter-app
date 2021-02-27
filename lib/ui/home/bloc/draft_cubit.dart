import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

// conversation id : draft
class DraftCubit extends Cubit<Map<String?, String?>> {
  DraftCubit() : super({});

  final TextEditingController textEditingController = TextEditingController();

  void update(String? name) {
    final text = textEditingController.text;
    state[name] = text.isEmpty ? null : text;
    emit(state);
  }

  void show(String? name) {
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
