import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';

import '../utils/extension/extension.dart';
import 'interactive_decorated_box.dart';
import 'unread_text.dart';

class SelectItem extends HookWidget {
  const SelectItem({
    required this.title,
    required this.icon,
    this.count = 0,
    this.mutedCount = 0,
    required this.onTap,
    this.selected = false,
    this.showTooltip = true,
    Key? key,
  }) : super(key: key);

  final Widget icon;
  final String title;
  final bool selected;
  final int count;
  final int mutedCount;
  final bool showTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showed = useState(false);
    final showedTooltip = useState(false);

    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
    );
    return InteractiveDecoratedBox.color(
      onEnter: (_) => showed.value = true,
      onExit: (_) => showed.value = false,
      onTap: onTap,
      decoration: selected == true
          ? boxDecoration.copyWith(color: context.theme.sidebarSelected)
          : boxDecoration,
      hoveringColor: context.theme.sidebarSelected
          .withOpacity(context.theme.sidebarSelected.opacity / 2),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        final hideTitle = boxConstraints.maxWidth < 75;
        final hideUnreadText = boxConstraints.maxWidth < 100;
        final titleWidget = Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.theme.text,
            fontSize: 14,
          ),
        );
        final dynamicColor = context.dynamicColor(
          const Color.fromRGBO(51, 51, 51, 0.16),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
        );
        final unreadTextWidget = UnreadText(
          data: '$count',
          backgroundColor: dynamicColor,
          textColor: context.theme.text,
        );
        return PortalEntry(
          visible: hideTitle &&
              hideUnreadText &&
              showTooltip &&
              (showed.value || showedTooltip.value),
          childAnchor: Alignment.centerRight,
          portalAnchor: Alignment.centerLeft,
          portal: InteractiveDecoratedBox.color(
            onEnter: (_) => showedTooltip.value = true,
            onExit: (_) => showedTooltip.value = false,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration:
                    boxDecoration.copyWith(color: context.theme.background),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    titleWidget,
                    if (count > 0) unreadTextWidget,
                  ].joinList(const SizedBox(width: 12)),
                ),
              ),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    icon,
                    if (!hideTitle) const SizedBox(width: 8),
                    if (!hideTitle)
                      Expanded(
                        child: titleWidget,
                      ),
                    if (count > 0 && !hideUnreadText) unreadTextWidget,
                  ],
                ),
              ),
              Positioned(
                top: 6,
                left: 28,
                child: AnimatedContainer(
                  height: 6,
                  width: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: count > 0 && hideUnreadText
                        ? count == mutedCount
                            ? dynamicColor
                            : context.theme.red
                        : Colors.transparent,
                  ),
                  duration: const Duration(milliseconds: 100),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
