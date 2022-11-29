import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../constants/resources.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';

class AudioPlayerBar extends HookWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final message = useCurrentPlayingMessage();
    final position = useAudioPlayerPosition();

    final duration = useMemoized<int>(() {
      if (message == null) {
        return 0;
      }
      return int.tryParse(message.mediaDuration ?? '') ?? 0;
    }, [message]);

    final progress = (position / duration).clamp(0.0, 1.0);

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

    if (state == PlaybackState.idle || state == PlaybackState.completed) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              ActionButton(
                name: state.isPlaying
                    ? Resources.assetsImagesAudioStopSvg
                    : Resources.assetsImagesAudioPlaySvg,
                onTap: () {
                  if (state.isPlaying) {
                    context.audioMessageService.pause();
                  } else {
                    context.audioMessageService.resume();
                  }
                },
              ),
              ConversationAvatarWidget(
                conversation: conversationItem,
                size: 32,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            value: progress,
            valueColor: AlwaysStoppedAnimation(context.theme.accent),
          ),
        ),
      ],
    );
  }
}
