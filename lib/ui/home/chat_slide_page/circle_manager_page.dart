import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/toast.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';

class CircleManagerPage extends HookWidget {
  const CircleManagerPage({
    Key? key,
    required this.name,
    required this.conversationId,
  }) : super(key: key);

  final String name;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final circles = useStream<List<ConversationCircleManagerItem>>(
      useMemoized(
        () => context
            .read<AccountServer>()
            .database
            .circlesDao
            .circleByConversationId(conversationId)
            .watch(),
        [conversationId],
      ),
      initialData: [],
    ).data as List<ConversationCircleManagerItem>;
    final otherCircles = useStream<List<ConversationCircleManagerItem>>(
      useMemoized(
        () => context
            .read<AccountServer>()
            .database
            .circlesDao
            .otherCircleByConversationId(conversationId)
            .watch(),
        [conversationId],
      ),
      initialData: [],
    ).data as List<ConversationCircleManagerItem>;

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).background,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).circleTitle(name)),
        actions: [
          MixinButton(
            child: SvgPicture.asset(
              Resources.assetsImagesIcAddSvg,
              width: 16,
              height: 16,
            ),
            backgroundTransparent: true,
            onTap: () async {
              final conversation = context.read<ConversationCubit>().state;
              if (conversation?.conversationId.isEmpty ?? true) return;

              final name = await showMixinDialog<String>(
                context: context,
                child: EditDialog(
                  title: Text(Localization.of(context).circles),
                  hintText: Localization.of(context).editCircleName,
                ),
              );

              await runFutureWithToast(
                context,
                context
                    .read<AccountServer>()
                    .createCircle(name!, [conversation!.conversationId]),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          if (circles.isNotEmpty)
            ...circles
                .map(
                  (e) => _CircleManagerItem(
                    name: e.name,
                    count: e.count,
                    circleId: e.circleId,
                    selected: true,
                  ),
                )
                .toList(),
          if (circles.isNotEmpty && otherCircles.isNotEmpty)
            const SizedBox(height: 10),
          if (otherCircles.isNotEmpty)
            ...otherCircles
                .map(
                  (e) => _CircleManagerItem(
                    name: e.name,
                    count: e.count,
                    circleId: e.circleId,
                    selected: false,
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

class _CircleManagerItem extends StatelessWidget {
  const _CircleManagerItem({
    Key? key,
    required this.name,
    required this.count,
    required this.circleId,
    required this.selected,
  }) : super(key: key);

  final String name;
  final int count;
  final String circleId;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        color: BrightnessData.themeOf(context).primary,
        child: Row(
          children: [
            GestureDetector(
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
              onTap: () async {
                final conversation = context.read<ConversationCubit>().state;
                if (conversation?.conversationId.isEmpty ?? true) return;

                if (selected) {
                  await runFutureWithToast(
                    context,
                    context.read<AccountServer>().circleRemoveConversation(
                        circleId, conversation!.conversationId),
                  );
                  return;
                }

                await runFutureWithToast(
                  context,
                  context.read<AccountServer>().circleAddConversation(
                        circleId,
                        conversation!.conversationId,
                        conversation.userId,
                      ),
                );
              },
            ),
            const SizedBox(width: 4),
            ClipOval(
              child: Container(
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(246, 247, 250, 1),
                  darkColor: const Color.fromRGBO(245, 247, 250, 1),
                ),
                height: 50,
                width: 50,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Resources.assetsImagesCircleSvg,
                  width: 18,
                  height: 18,
                  color: getCircleColorById(circleId),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Localization.of(context).conversationCount(count),
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
