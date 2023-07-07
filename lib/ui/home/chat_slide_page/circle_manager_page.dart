import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/dao/circle_dao.dart';
import '../../../db/database_event_bus.dart';

import '../../../utils/color_utils.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/toast.dart';
import '../bloc/conversation_cubit.dart';

class CircleManagerPage extends HookWidget {
  const CircleManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final state = context.read<ConversationCubit>().state;
      final conversationId = state?.conversationId;
      assert(conversationId != null);
      return conversationId;
    })!;

    final circles = useMemoizedStream<List<ConversationCircleManagerItem>>(
          () => context.database.circleDao
              .circleByConversationId(conversationId)
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateCircleConversationStream
            ],
            duration: kDefaultThrottleDuration,
          ),
          keys: [conversationId],
          initialData: [],
        ).data ??
        [];
    final otherCircles = useMemoizedStream<List<ConversationCircleManagerItem>>(
          () => context.database.circleDao
              .otherCircleByConversationId(conversationId)
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateCircleConversationStream
            ],
            duration: kDefaultThrottleDuration,
          ),
          keys: [conversationId],
          initialData: [],
        ).data ??
        [];

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.circles),
        actions: [
          ActionButton(
            name: Resources.assetsImagesIcAddSvg,
            onTap: () async {
              final conversation = context.read<ConversationCubit>().state;
              if (conversation?.conversationId.isEmpty ?? true) return;

              final name = await showMixinDialog<String>(
                context: context,
                child: EditDialog(
                  title: Text(context.l10n.circles),
                  hintText: context.l10n.editCircleName,
                ),
              );

              await runFutureWithToast(
                context.accountServer.createCircle(name!, [
                  CircleConversationRequest(
                    action: CircleConversationAction.add,
                    conversationId: conversation!.conversationId,
                    userId: conversation.userId,
                  ),
                ]),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          if (circles.isNotEmpty)
            ...circles.map(
              (e) => _CircleManagerItem(
                name: e.name,
                count: e.count,
                circleId: e.circleId,
                selected: true,
              ),
            ),
          if (circles.isNotEmpty && otherCircles.isNotEmpty)
            const SizedBox(height: 10),
          if (otherCircles.isNotEmpty)
            ...otherCircles.map(
              (e) => _CircleManagerItem(
                name: e.name,
                count: e.count,
                circleId: e.circleId,
                selected: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleManagerItem extends StatelessWidget {
  const _CircleManagerItem({
    required this.name,
    required this.count,
    required this.circleId,
    required this.selected,
  });

  final String name;
  final int count;
  final String circleId;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        color: context.theme.primary,
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                final conversation = context.read<ConversationCubit>().state;
                if (conversation?.conversationId.isEmpty ?? true) return;

                if (selected) {
                  await runFutureWithToast(
                    context.accountServer.circleRemoveConversation(
                        circleId, conversation!.conversationId),
                  );
                  return;
                }

                await runFutureWithToast(
                  context.accountServer.editCircleConversation(
                    circleId,
                    [
                      CircleConversationRequest(
                        action: CircleConversationAction.add,
                        conversationId: conversation!.conversationId,
                        userId: conversation.userId,
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SvgPicture.asset(
                  selected
                      ? Resources.assetsImagesCircleRemoveSvg
                      : Resources.assetsImagesCircleAddSvg,
                  height: 16,
                  width: 16,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ClipOval(
              child: Container(
                color: context.dynamicColor(
                  const Color.fromRGBO(246, 247, 250, 1),
                  darkColor: const Color.fromRGBO(245, 247, 250, 1),
                ),
                height: 50,
                width: 50,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Resources.assetsImagesCircleSvg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    getCircleColorById(circleId),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.circleSubtitle(count, count),
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
