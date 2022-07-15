import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../bloc/message_selection_cubit.dart';

class SelectionBottomBar extends StatelessWidget {
  const SelectionBottomBar({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Button(
              label: context.l10n.combineAndForward,
              iconAssetName: Resources.assetsImagesMessageTranscriptForwardSvg,
              onTap: () async {
                final result = await showConversationSelector(
                  context: context,
                  singleSelect: true,
                  title: context.l10n.forward,
                  onlyContact: false,
                );
                if (result == null || result.isEmpty) return;

                final cubit = context.read<MessageSelectionCubit>();
                final messageIds = cubit.state.selectedMessageIds;

                await runWithLoading(
                  context,
                  () => context.accountServer.sendTranscriptMessage(
                    messageIds.toList(),
                    result.first.encryptCategory!,
                    conversationId: result.first.conversationId,
                    recipientId: result.first.userId,
                  ),
                );
                cubit.clearSelection();
              },
            ),
            _Button(
              label: context.l10n.forwardOneByOne,
              iconAssetName: Resources.assetsImagesContextMenuForwardSvg,
              onTap: () async {
                final result = await showConversationSelector(
                  context: context,
                  singleSelect: true,
                  title: context.l10n.forward,
                  onlyContact: false,
                );
                if (result == null || result.isEmpty) return;

                final cubit = context.read<MessageSelectionCubit>();
                final messageIds = cubit.state.selectedMessageIds;

                await runWithLoading(context, () async {
                  for (final id in messageIds) {
                    await context.accountServer.forwardMessage(
                      id,
                      result.first.encryptCategory!,
                      conversationId: result.first.conversationId,
                      recipientId: result.first.userId,
                    );
                  }
                });
                cubit.clearSelection();
              },
            ),
            _Button(
              label: context.l10n.delete,
              iconAssetName: Resources.assetsImagesContextMenuDeleteSvg,
              onTap: () async {
                final confirm = await showConfirmMixinDialog(
                  context,
                  context.l10n.deleteSelectedMessageWarning,
                  positiveText: context.l10n.delete,
                );
                if (!confirm) {
                  return;
                }
                final cubit = context.read<MessageSelectionCubit>();
                final messagesToDelete = cubit.state.selectedMessageIds;
                d('messagesToDelete: $messagesToDelete');
                await runWithLoading(context, () async {
                  for (final id in messagesToDelete) {
                    await context.accountServer.deleteMessage(id);
                  }
                });
                cubit.clearSelection();
              },
            ),
          ],
        ),
      );
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.iconAssetName,
    required this.onTap,
  });

  final String label;
  final String iconAssetName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InteractiveDecoratedBox.color(
          onTap: onTap,
          decoration: const BoxDecoration(),
          hoveringColor: context.dynamicColor(
            const Color.fromRGBO(0, 0, 0, 0.03),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    iconAssetName,
                    width: 24,
                    height: 24,
                    color: context.theme.icon,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),
        ),
      );
}
