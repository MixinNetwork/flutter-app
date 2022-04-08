import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/toast.dart';
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
      width: 24,
      height: 24,
    );

    return CellGroup(
      child: Column(
        children: [
          CellItem(
            title: Text(context.l10n.off),
            trailing: expireIn.inSeconds < 1 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: Duration.zero,
              conversationId: conversationId,
            ),
          ),
          CellItem(
            title: Text('30 ${context.l10n.seconds}'),
            trailing: expireIn.inSeconds == 30 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: const Duration(seconds: 30),
              conversationId: conversationId,
            ),
          ),
          CellItem(
            title: Text('10 ${context.l10n.minutes}'),
            trailing: expireIn.inMinutes == 10 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: const Duration(minutes: 10),
              conversationId: conversationId,
            ),
          ),
          CellItem(
            title: Text('2 ${context.l10n.hours}'),
            trailing: expireIn.inHours == 2 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: const Duration(hours: 2),
              conversationId: conversationId,
            ),
          ),
          CellItem(
            title: Text('1 ${context.l10n.day}'),
            trailing: expireIn.inDays == 1 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: const Duration(days: 1),
              conversationId: conversationId,
            ),
          ),
          CellItem(
            title: Text('1 ${context.l10n.week}'),
            trailing: expireIn.inDays == 7 ? checkedIcon : null,
            onTap: () => _updateConversationExpireDuration(
              context,
              duration: const Duration(days: 7),
              conversationId: conversationId,
            ),
          ),
          CellItem(title: Text(context.l10n.disappearingCustomTime)),
        ],
      ),
    );
  }
}

// duration: zero to turn off disappearing messages.
Future<void> _updateConversationExpireDuration(
  BuildContext context, {
  required Duration duration,
  required String conversationId,
}) async {
  final api = context.accountServer.client.conversationApi;
  try {
    final response = await api.disappear(
      conversationId,
      DisappearRequest(duration: duration.inSeconds),
    );
    await context.database.conversationDao.updateConversation(response.data);
  } catch (error, stackTrace) {
    e('update conversation expire duration failed $error $stackTrace');
    await showToastFailed(context, error);
  }
}
