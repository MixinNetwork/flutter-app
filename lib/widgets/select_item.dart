import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/unread_text.dart';

import 'interacter_decorated_box.dart';

class SelectItem extends StatelessWidget {
  const SelectItem({
    this.title,
    this.asset,
    this.count = 0,
    this.onTap,
    this.selected = false,
  });

  final String asset;
  final String title;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InteractableDecoratedBox(
        onTap: onTap,
        decoration: selected == true
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              )
            : const BoxDecoration(),
        hoveringDecoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Image.asset(asset, width: 24),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              UnreadText(
                count: count,
                backgroundColor: Colors.white.withOpacity(0.4),
                textColor: const Color(0x2c3136).withOpacity(0.8),
              )
            ],
          ),
        ),
      ),
    );
  }
}
