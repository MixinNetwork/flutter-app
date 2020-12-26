import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/unread_text.dart';

import 'interacter_decorated_box.dart';

class SelectItem extends StatelessWidget {
  const SelectItem({
    this.title,
    this.asset,
    this.count = 0,
    this.onTap,
    this.selected = false,
    this.iconColor,
  });

  final Color iconColor;
  final String asset;
  final String title;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(51, 51, 51, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
    );
    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
    );
    return InteractableDecoratedBox(
      onTap: onTap,
      decoration: selected == true
          ? boxDecoration.copyWith(
              color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(0, 0, 0, 0.06),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
            ))
          : boxDecoration,
      hoveringDecoration: boxDecoration.copyWith(
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.asset(
              asset,
              width: 24,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
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
              textColor: textColor,
            )
          ],
        ),
      ),
    );
  }
}
