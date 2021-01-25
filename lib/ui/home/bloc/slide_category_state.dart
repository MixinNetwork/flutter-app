part of 'slide_category_cubit.dart';

enum SlideCategoryType {
  contacts,
  groups,
  bots,
  strangers,
  circle,
  setting,
}

class SlideCategoryState extends Equatable {
  const SlideCategoryState({
    @required this.type,
    this.id,
  });

  final SlideCategoryType type;
  final String id;

  @override
  List<Object> get props => [type, id];

  SlideCategoryState copyWith({
    final SlideCategoryType type,
    final String id,
  }) {
    return SlideCategoryState(
      type: type ?? this.type,
      id: id ?? this.id,
    );
  }
}
