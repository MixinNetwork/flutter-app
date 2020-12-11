import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  final Widget child;
  final Decoration decoration;
  final Decoration hoverDecoration;

  const HoverContainer({
    @required this.child,
    @required this.decoration,
    @required this.hoverDecoration,
  });

  @override
  _HoverContainerState createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  Decoration _decoration;

  @override
  void initState() {
    super.initState();
    _decoration = widget.decoration;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: _onEnter,
        onHover: _onHover,
        onExit: _onExit,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          child: widget.child,
          decoration: _decoration,
        ));
  }

  void _onEnter(_) {
    // // setState(() {
    //   _decoration = widget.decoration ?? widget.hoverDecoration;
    // });
  }

  void _onHover(_) {
    // setState(() {
    //   _decoration = widget.decoration ?? widget.hoverDecoration;
    // });
  }

  void _onExit(_) {
    // setState(() {
    //   print("${widget.decoration == null} \n");
    //   _decoration = widget.decoration;
    // });
  }
}
