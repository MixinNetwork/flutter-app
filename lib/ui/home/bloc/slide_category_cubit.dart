import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'slide_category_state.dart';

class SlideCategoryCubit extends Cubit<SlideCategoryState> {
  SlideCategoryCubit()
      : super(const SlideCategoryState(
            type: SlideCategoryType.contacts, id: 'Contacts'));

  void select(SlideCategoryType type, [String id]) =>
      emit(SlideCategoryState(type: type, id: id));
}
