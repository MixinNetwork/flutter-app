import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../bloc/conversation_cubit.dart';

class AudioPlayerBar extends HookWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final message = useCurrentPlayingMessage();

    final state = useAudioMessagePlayerState();

    final conversationItem = useMemoizedStream(
      () {
        if (message == null) {
          return Stream.value(null);
        }
        return context.database.conversationDao
            .conversationItem(message.conversationId)
            .watchSingleOrNull();
      },
      keys: [message?.conversationId],
    ).data;

    final selectedConversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
    );

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
        ConversationCubit.selectConversation(
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
                const SizedBox(width: 6),
                ActionButton(
                  name: state.isPlaying
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
                      ConversationAvatarWidget(
                        conversation: conversationItem,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          conversationItem?.validName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 6),
              ],
            ),
          ),
          _ProgressBar(message: message),
        ],
      ),
    );
  }
}

class _ProgressBar extends HookWidget {
  const _ProgressBar({required this.message});

  final MessageItem? message;

  @override
  Widget build(BuildContext context) {
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
        valueColor: AlwaysStoppedAnimation(context.theme.accent),
      ),
    );
  }
}
