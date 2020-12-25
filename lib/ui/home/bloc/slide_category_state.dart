part of 'slide_category_cubit.dart';

enum SlideCategoryType {
  people,
  circle,
}

class SlideCategoryState extends Equatable {
  const SlideCategoryState({
    this.type,
    this.name,
  });

  final SlideCategoryType type;
  final String name;

  @override
  List<Object> get props => [type, name];

  SlideCategoryState copyWith({
    final SlideCategoryType type,
    final String name,
  }) {
    return SlideCategoryState(
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }
}
