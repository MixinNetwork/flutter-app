import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/unread_text.dart';

import 'interacter_decorated_box.dart';

class SelectItem extends StatelessWidget {
  const SelectItem({
    required this.title,
    required this.icon,
    this.count = 0,
    required this.onTap,
    this.selected = false,
    Key? key,
  }) : super(key: key);

  final Widget icon;
  final String title;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
    );
    return InteractableDecoratedBox.color(
      onTap: onTap,
      decoration: selected == true
          ? boxDecoration.copyWith(
              color: BrightnessData.themeOf(context).sidebarSelected)
          : boxDecoration,
      child: LayoutBuilder(builder: (context, boxConstraints) {
        final hideTitle = boxConstraints.maxWidth < 75;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 8),
              if (!hideTitle)
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BrightnessData.themeOf(context).text,
                      fontSize: 14,
                    ),
                  ),
                ),
              UnreadText(
                count: count,
                backgroundColor: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(51, 51, 51, 0.16),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                ),
                textColor: BrightnessData.themeOf(context).text,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        );
      }),
    );
  }
}
