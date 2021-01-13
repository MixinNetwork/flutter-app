import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HoverOverlay extends StatefulWidget {
  const HoverOverlay({
    Key key,
    @required this.overlayBuilder,
    this.offset = Offset.zero,
    this.animationDuration,
    this.hideDuration,
    @required this.child,
    this.childAnchor = Alignment.topCenter,
    this.overlayAnchor = Alignment.bottomCenter,
    this.rootOverlay = true,
  }) : super(key: key);

  final bool rootOverlay;
  final Widget child;
  final WidgetBuilder overlayBuilder;
  final Alignment childAnchor;
  final Alignment overlayAnchor;
  final Offset offset;
  final Duration animationDuration;
  final Duration hideDuration;

  @override
  _HoverOverlayState createState() => _HoverOverlayState();
}

class _HoverOverlayState extends State<HoverOverlay> {
  final LayerLink _link = LayerLink();
  final _visibilityCubit = SimpleCubit<bool>(false);

  OverlayEntry _overlayEntry;

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _showOverlay(),
          onHover: (_) => _showOverlay(),
          onExit: (_) => _hideOverlay(),
          child: widget.child,
        ),
      );

  void _showOverlay() {
    _visibilityCubit.emit(true);
    if (_overlayEntry != null) return;
    _overlayEntry ??= OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) => Align(
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: widget.childAnchor,
          followerAnchor: widget.overlayAnchor,
          offset: widget.offset,
          child: MouseRegion(
            onEnter: (_) => _showOverlay(),
            onHover: (_) => _showOverlay(),
            onExit: (_) => _hideOverlay(),
            child: BlocBuilder(
              cubit: _visibilityCubit,
              builder: (context, state) => TweenAnimationBuilder<double>(
                tween: Tween<double>(end: state ? 1 : 0),
                curve: state ? Curves.ease : Curves.easeInExpo,
                duration: state
                    ? const Duration(milliseconds: 100)
                    : const Duration(milliseconds: 350),
                builder: (BuildContext context, double value, Widget child) =>
                    Opacity(
                  opacity: value,
                  child: Offstage(
                    child: child,
                    offstage: value == 0,
                  ),
                ),
                child: widget.overlayBuilder(context),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry);
  }

  void _hideOverlay() {
    _visibilityCubit.emit(false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
