import 'package:flutter/material.dart';

import '../utils/extension/extension.dart';
import 'interacter_decorated_box.dart';
import 'unread_text.dart';

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
    return InteractiveDecoratedBox.color(
      onTap: onTap,
      decoration: selected == true
          ? boxDecoration.copyWith(color: context.theme.sidebarSelected)
          : boxDecoration,
      child: LayoutBuilder(builder: (context, boxConstraints) {
        final hideTitle = boxConstraints.maxWidth < 75;
        final hideUnreadText = boxConstraints.maxWidth < 100;
        return Padding(
          padding: const EdgeInsets.all(8),
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
                      color: context.theme.text,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (count > 0 && !hideUnreadText)
                UnreadText(
                  data: '$count',
                  backgroundColor: context.dynamicColor(
                    const Color.fromRGBO(51, 51, 51, 0.16),
                    darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                  ),
                  textColor: context.theme.text,
                ),
            ],
          ),
        );
      }),
    );
  }
}
