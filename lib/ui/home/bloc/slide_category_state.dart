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
    this.name,
    this.id,
  });

  final SlideCategoryType type;
  final String name;
  final String id;

  @override
  List<Object> get props => [type, name];

  SlideCategoryState copyWith({
    final SlideCategoryType type,
    final String name,
    final String id,
  }) {
    return SlideCategoryState(
      type: type ?? this.type,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }
}
