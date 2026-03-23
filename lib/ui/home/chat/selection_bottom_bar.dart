import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/message_optimize.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/message_selection_provider.dart';
import '../../provider/ui_context_providers.dart';

class SelectionBottomBar extends HookConsumerWidget {
  const SelectionBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final canForward = ref.watch(
      messageSelectionProvider.select((value) => value.canForward),
    );

    final canCombineForward = ref.watch(
      messageSelectionProvider.select((value) => value.canCombineForward),
    );

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Button(
            label: l10n.combineAndForward,
            iconAssetName: Resources.assetsImagesMessageTranscriptForwardSvg,
            enable: canCombineForward,
            onTap: () async {
              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                title: l10n.forward,
                onlyContact: false,
              );
              if (result == null || result.isEmpty) return;

              final selection = ref.read(messageSelectionProvider);
              final messageIds = selection.selectedMessageIds;

              await runWithLoading(
                () => accountServer.sendTranscriptMessage(
                  messageIds.toList(),
                  result.first.encryptCategory!,
                  conversationId: result.first.conversationId,
                  recipientId: result.first.userId,
                ),
              );
              ref.read(messageSelectionProvider.notifier).clearSelection();
            },
          ),
          _Button(
            label: l10n.oneByOneForward,
            iconAssetName: Resources.assetsImagesContextMenuForwardSvg,
            enable: canForward,
            onTap: () async {
              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                title: l10n.forward,
                onlyContact: false,
              );
              if (result == null || result.isEmpty) return;

              final selection = ref.read(messageSelectionProvider);
              final messageIds = selection.selectedMessageIds;

              await runWithLoading(() async {
                for (final id in messageIds) {
                  await accountServer.forwardMessage(
                    id,
                    result.first.encryptCategory!,
                    conversationId: result.first.conversationId,
                    recipientId: result.first.userId,
                  );
                }
              });
              ref.read(messageSelectionProvider.notifier).clearSelection();
            },
          ),
          _Button(
            label: l10n.copy,
            iconAssetName: Resources.assetsImagesCopySvg,
            onTap: () async => runFutureWithToast(
              (() async {
                final messageSelection = ref.read(messageSelectionProvider);

                final selectedMessageIds = messageSelection.selectedMessageIds;
                final messages = await database.messageDao
                    .messageItemByMessageIds(
                      selectedMessageIds.toList(),
                    )
                    .get();

                final dateFormat = DateFormat.yMd().add_Hms();
                final text = messages
                    .map((e) {
                      var content = e.content;
                      if (!e.type.isText) {
                        content = messagePreviewOptimize(
                          e.status,
                          e.type,
                          e.content,
                        );
                      }
                      return '${e.userFullName}, (${dateFormat.format(e.createdAt.toLocal())}):\n$content';
                    })
                    .join('\n\n');

                await Clipboard.setData(ClipboardData(text: text));

                ref.read(messageSelectionProvider.notifier).clearSelection();
              })(),
            ),
          ),
          _Button(
            label: l10n.delete,
            iconAssetName: Resources.assetsImagesContextMenuDeleteSvg,
            onTap: () async {
              final selection = ref.read(messageSelectionProvider);
              final messagesToDelete = selection.selectedMessageIds;

              final canRecall = selection.canRecall;

              final confirm = await showConfirmMixinDialog(
                context,
                l10n.chatDeleteMessage(
                  messagesToDelete.length,
                  messagesToDelete.length,
                ),
                positiveText: l10n.delete,
                neutralText: canRecall ? l10n.deleteForEveryone : null,
              );
              if (confirm == null) return;
              d('messagesToDelete: $messagesToDelete');
              await runWithLoading(() async {
                if (confirm == DialogEvent.positive) {
                  for (final id in messagesToDelete) {
                    await accountServer.deleteMessage(id);
                  }
                  return;
                }

                if (confirm == DialogEvent.neutral) {
                  await accountServer.sendRecallMessage(
                    messagesToDelete.toList(),
                    conversationId: ref.read(currentConversationIdProvider),
                  );
                }
              });
              ref.read(messageSelectionProvider.notifier).clearSelection();
            },
          ),
        ],
      ),
    );
  }
}

class _Button extends ConsumerWidget {
  const _Button({
    required this.label,
    required this.iconAssetName,
    required this.onTap,
    this.enable = true,
  });

  final String label;
  final String iconAssetName;
  final VoidCallback onTap;
  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final hoverColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
      ),
    );
    Widget child = Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAssetName,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.icon,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
    if (enable) {
      child = InteractiveDecoratedBox.color(
        decoration: const BoxDecoration(),
        hoveringColor: hoverColor,
        onTap: onTap,
        child: child,
      );
    } else {
      child = Opacity(opacity: 0.5, child: child);
    }
    return Expanded(child: child);
  }
}
