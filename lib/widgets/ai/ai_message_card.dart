import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter/rendering.dart' show SelectedContent, SelectionStatus;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart' hide Offset;
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/platform.dart';
import '../markdown.dart';
import '../menu.dart';
import '../message/item/text/selectable.dart';
import '../message/message_bubble.dart';
import '../message/message_datetime_and_status.dart';
import '../message/message_layout.dart';
import '../message/message_style.dart';
import '../qr_code.dart';

class AiMessageCard extends StatelessWidget {
  const AiMessageCard({
    required this.message,
    super.key,
    this.prev,
    this.next,
  });

  final AiChatMessage message;
  final AiChatMessage? prev;
  final AiChatMessage? next;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final sameRolePrev = prev?.role == message.role;
    final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
    final sameRoleNext = next?.role == message.role;
    final mergedWithPrev = sameDayPrev && sameRolePrev;
    final mergedWithNext = sameDayNext && sameRoleNext;
    final showAssistantMeta = !isUser && !mergedWithPrev;
    final bubbleColor = _bubbleColor(
      context,
      isUser: isUser,
      status: message.status,
    );
    final body = _AiBubble(
      isCurrentUser: isUser,
      showNip: !mergedWithNext && !showAssistantMeta,
      color: bubbleColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _AiMessageBody(message: message),
      ),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showAssistantMeta)
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: Text(
              'AI Assistant',
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: context.messageStyle.statusFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        body,
      ],
    );

    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(
          left: 65,
          right: 16,
          top: mergedWithPrev ? 0 : 8,
          bottom: 2,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: _AiMessageMenu(
            message: message,
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: mergedWithPrev ? 0 : 8, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: showAssistantMeta
                ? _AiAvatar(thinking: message.status == 'pending')
                : null,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _AiMessageMenu(
                message: message,
                child: content,
              ),
            ),
          ),
          const SizedBox(width: 65),
        ],
      ),
    );
  }
}

class _AiMessageBody extends StatelessWidget {
  const _AiMessageBody({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final content = message.content.trim();
    final text = content.isNotEmpty
        ? content
        : message.status == 'error'
        ? (message.errorText ?? 'Request failed')
        : 'Thinking...';
    final statusColor = _statusColor(
      context,
      isUser: isUser,
      status: message.status,
    );

    Widget body;
    final textStyle = TextStyle(
      color: context.theme.text,
      fontSize: context.messageStyle.primaryFontSize,
      height: 1.45,
    );

    if (isUser || message.status == 'error') {
      body = _AiSelectableText(text: text, style: textStyle);
    } else {
      body = DefaultTextStyle.merge(
        style: textStyle,
        child: MarkdownColumn(data: text, selectable: true),
      );
    }

    return MessageLayout(
      spacing: 6,
      content: body,
      dateAndStatus: _AiFooter(
        isUser: isUser,
        status: message.status,
        color: statusColor,
        dateTime: message.createdAt,
      ),
    );
  }
}

class _AiSelectableText extends StatefulWidget {
  const _AiSelectableText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_AiSelectableText> createState() => _AiSelectableTextState();
}

class _AiSelectableTextState extends State<_AiSelectableText> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'ai_message_selection_focus',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Text(widget.text, style: widget.style);
    if (!kPlatformIsDesktop) {
      return child;
    }
    return SelectableRegion(
      focusNode: _focusNode,
      contextMenuBuilder: (context, state) => const SizedBox.shrink(),
      selectionControls: desktopTextSelectionHandleControls,
      child: child,
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.child,
    required this.isCurrentUser,
    required this.color,
    required this.showNip,
  });

  final Widget child;
  final bool isCurrentUser;
  final Color color;
  final bool showNip;

  @override
  Widget build(BuildContext context) {
    final clipper = BubbleClipper(
      currentUser: isCurrentUser,
      showNip: showNip,
    );

    return CustomPaint(
      painter: BubblePainter(color: color, clipper: clipper),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: MessageBubbleNipPadding(
          currentUser: isCurrentUser,
          child: child,
        ),
      ),
    );
  }
}

class _AiAvatar extends HookWidget {
  const _AiAvatar({required this.thinking});

  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final background = context.dynamicColor(
      const Color.fromRGBO(227, 237, 213, 1),
      darkColor: const Color.fromRGBO(64, 78, 56, 1),
    );
    final foreground = context.dynamicColor(
      const Color.fromRGBO(54, 87, 35, 1),
      darkColor: const Color.fromRGBO(214, 235, 204, 1),
    );
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    );
    useEffect(() {
      if (!thinking || disableAnimations) {
        controller
          ..stop()
          ..value = 0;
        return null;
      }
      controller.repeat();
      return null;
    }, [thinking, disableAnimations, controller]);

    final progress = useAnimation(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final scale = !thinking || disableAnimations
        ? 1.0
        : 1 + (0.03 * (0.5 - (progress - 0.5).abs()) * 2);
    final glowAlpha = !thinking || disableAnimations ? 0.0 : 0.16 * progress;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: glowAlpha == 0
              ? null
              : [
                  BoxShadow(
                    color: foreground.withValues(alpha: glowAlpha),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          Resources.assetsImagesBotFillSvg,
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _AiMessageMenu extends StatelessWidget {
  const _AiMessageMenu({
    required this.message,
    required this.child,
  });

  final AiChatMessage message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = _menuCopyText(message);

    return Builder(
      builder: (childContext) => CustomContextMenuWidget(
        hitTestBehavior: HitTestBehavior.translucent,
        desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
        menuProvider: (_) {
          final selectedContent = _findSelectedContent(childContext);
          return MenusWithSeparator(
            childrens: [
              [
                MenuAction(
                  image: MenuImage.icon(Icons.copy),
                  title: context.l10n.copy,
                  callback: () {
                    Clipboard.setData(ClipboardData(text: content));
                  },
                ),
                if (selectedContent != null)
                  MenuAction(
                    image: MenuImage.icon(Icons.copy),
                    title: context.l10n.copySelectedText,
                    callback: () {
                      Clipboard.setData(
                        ClipboardData(text: selectedContent.plainText),
                      );
                    },
                  ),
                if (content.isNotEmpty)
                  MenuAction(
                    image: MenuImage.icon(Icons.qr_code),
                    title: context.l10n.generateQrcode,
                    callback: () => showQrCodeDialog(context, content),
                  ),
              ],
              [
                MenuAction(
                  image: MenuImage.icon(Icons.data_object),
                  title: 'Copy AI message',
                  callback: () {
                    Clipboard.setData(ClipboardData(text: message.toString()));
                  },
                ),
              ],
            ],
          );
        },
        child: child,
      ),
    );
  }
}

SelectedContent? _findSelectedContent(BuildContext context) {
  SelectableRegionState? findSelectableRegionState(BuildContext context) {
    if (context is! Element) {
      return null;
    }
    if (context.widget is SelectableRegion) {
      return (context as StatefulElement).state as SelectableRegionState;
    }

    SelectableRegionState? found;
    context.visitChildren((element) {
      if (found != null) return;
      final result = findSelectableRegionState(element);
      if (result != null) {
        found = result;
      }
    });
    return found;
  }

  final selectableRegion = findSelectableRegionState(context);
  final status = selectableRegion?.selectable?.value.status;
  final content = selectableRegion?.selectable?.getSelectedContent();
  if (status == SelectionStatus.uncollapsed && content != null) {
    return content;
  }
  return null;
}

class _AiStatusBadge extends HookWidget {
  const _AiStatusBadge({
    required this.isUser,
    required this.status,
    required this.color,
  });

  final bool isUser;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (status == 'pending') {
      return _AiThinkingIndicator(color: color);
    }

    return Icon(
      _statusIcon(messageRoleIsUser: isUser, status: status),
      size: 12,
      color: color,
    );
  }
}

class _AiFooter extends StatelessWidget {
  const _AiFooter({
    required this.isUser,
    required this.status,
    required this.color,
    required this.dateTime,
  });

  final bool isUser;
  final String status;
  final Color color;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) => MessageMetaRow(
    dateTime: dateTime,
    trailingSpacing: 4,
    trailing: _AiStatusBadge(
      isUser: isUser,
      status: status,
      color: color,
    ),
  );
}

class _AiThinkingIndicator extends HookWidget {
  const _AiThinkingIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Icon(Icons.more_horiz_rounded, size: 12, color: color);
    }

    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);

    return RotationTransition(
      turns: controller,
      child: CustomPaint(
        size: const Size.square(12),
        painter: _AiThinkingIndicatorPainter(color: color),
      ),
    );
  }
}

class _AiThinkingIndicatorPainter extends CustomPainter {
  const _AiThinkingIndicatorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 1;

    final track = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawCircle(center, radius, track)
      ..drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.2,
        1.95,
        false,
        arc,
      );
  }

  @override
  bool shouldRepaint(covariant _AiThinkingIndicatorPainter oldDelegate) =>
      oldDelegate.color != color;
}

IconData _statusIcon({
  required bool messageRoleIsUser,
  required String status,
}) {
  if (status == 'error') return Icons.error_outline_rounded;
  if (messageRoleIsUser) return Icons.auto_awesome_rounded;
  return Icons.smart_toy_rounded;
}

Color _bubbleColor(
  BuildContext context, {
  required bool isUser,
  required String status,
}) {
  if (status == 'error') {
    return context.dynamicColor(
      const Color.fromRGBO(255, 235, 235, 1),
      darkColor: const Color.fromRGBO(88, 46, 46, 1),
    );
  }

  if (isUser) {
    return context.dynamicColor(
      const Color.fromRGBO(255, 241, 214, 1),
      darkColor: const Color.fromRGBO(96, 76, 34, 1),
    );
  }

  return context.dynamicColor(
    const Color.fromRGBO(228, 245, 239, 1),
    darkColor: const Color.fromRGBO(43, 77, 65, 1),
  );
}

Color _statusColor(
  BuildContext context, {
  required bool isUser,
  required String status,
}) {
  if (status == 'error') {
    return context.dynamicColor(
      const Color.fromRGBO(193, 63, 63, 1),
      darkColor: const Color.fromRGBO(255, 173, 173, 1),
    );
  }

  if (isUser) {
    return context.dynamicColor(
      const Color.fromRGBO(176, 107, 18, 1),
      darkColor: const Color.fromRGBO(255, 214, 143, 1),
    );
  }

  if (status == 'pending') {
    return context.dynamicColor(
      const Color.fromRGBO(46, 123, 110, 1),
      darkColor: const Color.fromRGBO(159, 230, 217, 1),
    );
  }

  return context.dynamicColor(
    const Color.fromRGBO(33, 126, 96, 1),
    darkColor: const Color.fromRGBO(150, 238, 210, 1),
  );
}

String _menuCopyText(AiChatMessage message) {
  final content = message.content.trim();
  if (content.isNotEmpty) return content;
  if (message.status == 'error') {
    return message.errorText ?? 'Request failed';
  }
  return 'Thinking...';
}
