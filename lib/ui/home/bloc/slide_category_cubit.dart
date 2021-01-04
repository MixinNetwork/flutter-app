import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'slide_category_state.dart';

class SlideCategoryCubit extends Cubit<SlideCategoryState> {
  SlideCategoryCubit()
      : super(const SlideCategoryState(
            type: SlideCategoryType.people, name: 'Contacts'));

  void select(SlideCategoryType type, [String name]) =>
      emit(SlideCategoryState(type: type, name: name));
}
