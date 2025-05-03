import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../provider/conversation_provider.dart';

class AudioPlayerBar extends HookConsumerWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = useCurrentPlayingMessage();

    final state = useAudioMessagePlayerState();

    final conversationItem =
        useMemoizedStream(() {
          if (message == null) {
            return Stream.value(null);
          }
          return context.database.conversationDao
              .conversationItem(message.conversationId)
              .watchSingleOrNullWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateConversationStream([
                    message.conversationId,
                  ]),
                ],
                duration: kSlowThrottleDuration,
              );
        }, keys: [message?.conversationId]).data;

    final selectedConversationId = ref.watch(currentConversationIdProvider);

    if (state == PlaybackState.idle ||
        state == PlaybackState.completed ||
        conversationItem?.conversationId == selectedConversationId) {
      return const SizedBox.shrink();
    }

    return InteractiveDecoratedBox(
      onTap: () {
        if (conversationItem == null) {
          return;
        }
        ConversationStateNotifier.selectConversation(
          context,
          conversationItem.conversationId,
          conversation: conversationItem,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const _PlaybackSpeedButton(),
                ActionButton(
                  name:
                      state.isPlaying
                          ? Resources.assetsImagesPlayerPauseSvg
                          : Resources.assetsImagesPlayerPlaySvg,
                  color: context.theme.icon,
                  onTap: () {
                    if (state.isPlaying) {
                      context.audioMessageService.pause();
                    } else {
                      context.audioMessageService.resume();
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Icon(conversation: conversationItem),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          conversationItem?.validName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ActionButton(
                  name: Resources.assetsImagesIcCloseSvg,
                  color: context.theme.icon,
                  onTap: () {
                    context.audioMessageService.stop();
                  },
                ),
              ],
            ),
          ),
          _ProgressBar(message: message),
        ],
      ),
    );
  }
}

class _PlaybackSpeedButton extends HookConsumerWidget {
  const _PlaybackSpeedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = useAudioPlayerSpeed();
    return ActionButton(
      child: Center(
        child: Text(
          '2X',
          style: TextStyle(
            color:
                speed == 2 ? context.theme.accent : context.theme.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {
        if (speed == 1) {
          context.audioMessageService.setPlaySpeed(2);
        } else {
          context.audioMessageService.setPlaySpeed(1);
        }
      },
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.conversation});

  final ConversationItem? conversation;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    width: 40,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child:
              conversation == null
                  ? const SizedBox.square(dimension: 32)
                  : ConversationAvatarWidget(
                    conversation: conversation,
                    size: 32,
                  ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: SvgPicture.asset(
            Resources.assetsImagesAudioSvg,
            colorFilter: ColorFilter.mode(context.theme.icon, BlendMode.srcIn),
            width: 16,
            height: 16,
          ),
        ),
      ],
    ),
  );
}

class _ProgressBar extends HookConsumerWidget {
  const _ProgressBar({required this.message});

  final MessageItem? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = useAudioPlayerPosition();

    final duration = useMemoized<int>(() {
      if (message == null) {
        return 0;
      }
      return int.tryParse(message!.mediaDuration ?? '') ?? 0;
    }, [message]);

    final progress = (position / duration).clamp(0.0, 1.0);
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation(context.theme.accent),
      ),
    );
  }
}
