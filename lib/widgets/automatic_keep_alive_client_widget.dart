import 'package:flutter/widgets.dart';

class AutomaticKeepAliveClientWidget extends StatefulWidget {
  const AutomaticKeepAliveClientWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _AutomaticKeepAliveClientWidgetState createState() =>
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
