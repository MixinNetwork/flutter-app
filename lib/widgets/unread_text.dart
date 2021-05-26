import 'package:flutter/material.dart';

class UnreadText extends StatelessWidget {
  const UnreadText({
    Key? key,
    required this.data,
    this.backgroundColor,
    this.textColor,
    this.fontWeight,
  }) : super(key: key);

  final Color? backgroundColor;
  final Color? textColor;
  final FontWeight? fontWeight;
  final String data;

  @override
  Widget build(BuildContext context) => Container(
        height: 20,
        width: 26,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          data,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: fontWeight,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      );
}
