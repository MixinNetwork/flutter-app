import 'package:flutter/widgets.dart';

class AutomaticKeepAliveClientWidget extends StatefulWidget {
  const AutomaticKeepAliveClientWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AutomaticKeepAliveClientWidget> createState() =>
      _AutomaticKeepAliveClientWidgetState();
}

class _AutomaticKeepAliveClientWidgetState
    extends State<AutomaticKeepAliveClientWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
