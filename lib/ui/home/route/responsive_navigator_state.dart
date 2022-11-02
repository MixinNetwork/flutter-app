part of 'responsive_navigator_cubit.dart';

class ResponsiveNavigatorState extends Equatable {
  const ResponsiveNavigatorState({
    this.pages = const [],
    this.routeMode = false,
  });

  final List<MaterialPage> pages;
  final bool routeMode;

  @override
  List<Object?> get props => [
        routeMode,
        ...pages.map((e) => Tuple4(
              e.key,
              e.name,
              e.arguments,
              e.child.key,
            ))
      ];

  ResponsiveNavigatorState copyWith({
     List<MaterialPage>? pages,
     bool? routeMode,
  }) =>
      ResponsiveNavigatorState(
        pages: pages ?? this.pages,
        routeMode: routeMode ?? this.routeMode,
      );
}
