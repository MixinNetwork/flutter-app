import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/unread_text.dart';

import 'hover_container.dart';

class SelectItem extends StatelessWidget {
  final String asset;
  final String title;
  final int groupValue;
  final int value;
  final int count;
  final Function onTap;
  const SelectItem(
      {this.title,
      this.asset,
      this.count = 0,
      this.onTap,
      this.groupValue,
      this.value});

  @override
  Widget build(BuildContext context) {
    return HoverContainer(
      onTap: onTap,
      groupValue: groupValue,
      value: value,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      hoverDecoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.asset(asset, width: 24),
            SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            UnreadText(
              count: count,
              backgroundColor: Colors.white.withOpacity(0.4),
              textColor: Color(0x2c3136).withOpacity(0.8),
            )
          ],
        ),
      ),
    );
  }
}
