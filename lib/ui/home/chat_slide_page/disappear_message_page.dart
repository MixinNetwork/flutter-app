import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cell.dart';
import '../bloc/conversation_cubit.dart';

class DisappearMessagePage extends StatelessWidget {
  const DisappearMessagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.primary,
        appBar: MixinAppBar(
          title: Text(context.l10n.disappearingMessages),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              SvgPicture.asset(
                Resources.assetsImagesDisappearingMessageSvg,
                width: 70,
                height: 70,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  context.l10n.disappearingMessagesDescription,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const _Options(),
            ],
          ),
        ),
      );
}

class _Options extends HookWidget {
  const _Options({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });
    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) =>
          state?.isLoaded == true && state?.conversationId == conversationId,
    )!;

    final expireIn = conversation.conversation?.expireDuration ?? Duration.zero;

    final checkedIcon = SvgPicture.asset(
      Resources.assetsImagesCheckedSvg,
      width: 30,
      height: 30,
    );

    return CellGroup(
      child: Column(
        children: [
          CellItem(
            title: Text(context.l10n.off),
            trailing: expireIn.inSeconds < 1 ? checkedIcon : null,
          ),
          CellItem(
            title: Text('30 ${context.l10n.seconds}'),
            trailing: expireIn.inSeconds == 30 ? checkedIcon : null,
          ),
          CellItem(
            title: Text('10 ${context.l10n.minutes}'),
            trailing: expireIn.inMinutes == 10 ? checkedIcon : null,
          ),
          CellItem(
            title: Text('2 ${context.l10n.hours}'),
            trailing: expireIn.inHours == 2 ? checkedIcon : null,
          ),
          CellItem(
            title: Text('1 ${context.l10n.day}'),
            trailing: expireIn.inDays == 1 ? checkedIcon : null,
          ),
          CellItem(
            title: Text('1 ${context.l10n.week}'),
            trailing: expireIn.inDays == 7 ? checkedIcon : null,
          ),
          CellItem(title: Text(context.l10n.disappearingCustomTime)),
        ],
      ),
    );
  }
}
