import 'dart:math';

import 'package:flutter/material.dart';

class UnreadText extends StatelessWidget {
  const UnreadText({
    Key key,
    @required this.count,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  final Color backgroundColor;
  final Color textColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: count > 0,
      child: Container(
        height: 20,
        width: 26,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '${min(count, 99)}',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
