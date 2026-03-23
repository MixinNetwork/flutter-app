import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../providers/home_scope_providers.dart';

final _audioPlayerConversationProvider = StreamProvider.autoDispose
    .family<ConversationItem?, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(null);
      }
      return database.conversationDao
          .conversationItem(conversationId)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateConversationStream([
                conversationId,
              ]),
            ],
            duration: kSlowThrottleDuration,
          );
    });

class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final message = ref.watch(currentPlayingAudioMessageProvider).value;
    final state =
        ref.watch(audioPlayerPlaybackStateProvider).value ?? PlaybackState.idle;
    final conversationItem = message == null
        ? null
        : ref
              .watch(
                _audioPlayerConversationProvider(message.conversationId),
              )
              .value;

    final selectedConversationId = ref.watch(currentConversationIdProvider);
    final audioService = ref.read(audioMessagePlayServiceProvider);

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
          ref.container,
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
                  name: state.isPlaying
                      ? Resources.assetsImagesPlayerPauseSvg
                      : Resources.assetsImagesPlayerPlaySvg,
                  color: theme.icon,
                  onTap: () {
                    if (state.isPlaying) {
                      audioService.pause();
                    } else {
                      audioService.resume();
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
                            color: theme.text,
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
                  color: theme.icon,
                  onTap: audioService.stop,
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

class _PlaybackSpeedButton extends ConsumerWidget {
  const _PlaybackSpeedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final speed = ref.watch(audioPlayerSpeedProvider).value ?? 1;
    final audioService = ref.read(audioMessagePlayServiceProvider);
    return ActionButton(
      child: Center(
        child: Text(
          '2X',
          style: TextStyle(
            color: speed == 2 ? theme.accent : theme.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {
        if (speed == 1) {
          audioService.setPlaySpeed(2);
        } else {
          audioService.setPlaySpeed(1);
        }
      },
    );
  }
}

class _Icon extends ConsumerWidget {
  const _Icon({required this.conversation});

  final ConversationItem? conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return SizedBox(
      height: 32,
      width: 40,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: conversation == null
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
              colorFilter: ColorFilter.mode(
                theme.icon,
                BlendMode.srcIn,
              ),
              width: 16,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  const _ProgressBar({required this.message});

  final MessageItem? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final position = ref.watch(audioPlayerPositionProvider).value ?? 0;
    final duration = message == null
        ? 0
        : int.tryParse(message!.mediaDuration ?? '') ?? 0;

    final progress = (position / duration).clamp(0.0, 1.0);
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation(
          theme.accent,
        ),
      ),
    );
  }
}
