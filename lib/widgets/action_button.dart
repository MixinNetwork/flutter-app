import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton(
      {this.name, this.onTap, this.padding = 8.0, this.size = 24});

  final String name;
  final Function onTap;
  final double padding;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(name, width: size, height: size),
      ),
    );
  }
}
