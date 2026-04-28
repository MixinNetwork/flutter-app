import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter/rendering.dart' show SelectedContent, SelectionStatus;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:super_context_menu/super_context_menu.dart';

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

const _copyAiMessageTitle = 'Copy AI Message';

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
    final body = isUser
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _AiMessageBody(message: message),
          )
        : _AiMessageBody(message: message);

    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(
          left: 72,
          right: 8,
          top: mergedWithPrev ? 4 : 14,
          bottom: 4,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: _AiMessageMenu(
            message: message,
            child: _AiBubble(
              isCurrentUser: true,
              showNip: !mergedWithNext,
              color: _bubbleColor(
                context,
                isUser: true,
                status: message.status,
              ),
              child: body,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: mergedWithPrev ? 6 : 18,
        bottom: 6,
      ),
      child: _AiMessageMenu(
        message: message,
        child: body,
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
    final text = _displayText(message);

    Widget body;
    final textStyle = TextStyle(
      color: message.status == 'error'
          ? context.theme.ai.error
          : context.theme.text,
      fontSize: context.messageStyle.primaryFontSize,
      height: 1.45,
    );

    if (isUser || message.status == 'error') {
      body = _AiSelectableText(text: text, style: textStyle);
    } else {
      final cacheKey = buildMarkdownCacheKey(
        namespace: 'ai',
        id: message.id,
      );
      body = DefaultTextStyle.merge(
        style: textStyle,
        child: MarkdownColumn(
          data: text,
          selectable: true,
          cacheKey: cacheKey,
          streaming: message.status == 'pending',
        ),
      );
    }

    return MessageLayout(
      spacing: 6,
      content: body,
      dateAndStatus: _AiFooter(
        isUser: isUser,
        model: message.model,
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
                  title: _copyAiMessageTitle,
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

class _AiFooter extends StatelessWidget {
  const _AiFooter({
    required this.isUser,
    required this.model,
    required this.dateTime,
  });

  final bool isUser;
  final String? model;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return MessageMetaRow(dateTime: dateTime);
    }

    final metaColor = context.dynamicColor(
      const Color.fromRGBO(131, 145, 158, 1),
      darkColor: const Color.fromRGBO(128, 131, 134, 1),
    );
    final textStyle = TextStyle(
      fontSize: context.messageStyle.statusFontSize,
      color: metaColor,
    );
    final dateTimeText = DateFormat.Hm().format(dateTime.toLocal());
    final trimmedModel = isUser ? null : model?.trim();

    return SelectionContainer.disabled(
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Text(dateTimeText, style: textStyle),
            if (trimmedModel != null && trimmedModel.isNotEmpty) ...[
              const Spacer(),
              Text(trimmedModel, style: textStyle),
            ],
          ],
        ),
      ),
    );
  }
}

Color _bubbleColor(
  BuildContext context, {
  required bool isUser,
  required String status,
}) {
  if (status == 'error') {
    return context.theme.ai.errorBubble;
  }

  if (isUser) {
    return context.theme.ai.userBubble;
  }

  return context.theme.ai.assistantBubble;
}

String _menuCopyText(AiChatMessage message) => _displayText(message);

String _displayText(AiChatMessage message) {
  final content = message.content.trim();
  if (content.isNotEmpty) return content;
  if (message.status == 'error') {
    return message.errorText ?? 'Request failed';
  }
  if (message.status == 'pending') return 'Thinking...';
  return message.errorText ?? 'No response';
}
