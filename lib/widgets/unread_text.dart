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
        constraints:
            const BoxConstraints(minWidth: 26, minHeight: 20, maxHeight: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        child: Text(
          data,
          maxLines: 1,
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
