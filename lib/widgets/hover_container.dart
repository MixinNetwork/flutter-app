import 'package:flutter/material.dart';

// TODO
class HoverContainer extends StatefulWidget {
  const HoverContainer(
      {@required this.child,
      @required this.decoration,
      @required this.hoverDecoration,
      @required this.groupValue,
      @required this.value,
      this.onTap});

  final Widget child;
  final Decoration decoration;
  final Decoration hoverDecoration;
  final int groupValue;
  final int value;
  final Function onTap;

  @override
  _HoverContainerState createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool get _selected => widget.value == widget.groupValue;

  @override
  void initState() {
    super.initState();
    if (_selected) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: MouseRegion(
        onHover: _onHover,
        onExit: _onExit,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          child: widget.child,
          decoration: defaultDecoration(),
        ),
      ),
    );
  }

  void _onHover(_) {
    setState(() {});
  }

  Decoration defaultDecoration() {
    if (widget.groupValue == null) {
      return null;
    }
    if (_selected) {
      return widget.decoration;
    } else {
      return null;
    }
  }

  void _onExit(_) {
    setState(() {});
  }
}
