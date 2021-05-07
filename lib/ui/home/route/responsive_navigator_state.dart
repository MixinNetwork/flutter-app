part of 'responsive_navigator_cubit.dart';

class ResponsiveNavigatorState extends Equatable {
  const ResponsiveNavigatorState({
    this.pages = const [],
    this.navigationMode = false,
  });

  final List<MaterialPage> pages;
  final bool navigationMode;

  @override
  List<Object?> get props => [
        navigationMode,
        ...pages.map((e) => Tuple4(
              e.key,
              e.name,
              e.arguments,
              e.child.key,
            ))
      ];

  ResponsiveNavigatorState copyWith({
    final List<MaterialPage>? pages,
    final bool? navigationMode,
  }) =>
      ResponsiveNavigatorState(
        pages: pages ?? this.pages,
        navigationMode: navigationMode ?? this.navigationMode,
      );
}
