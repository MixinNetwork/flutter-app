import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../blaze/vo/transcript_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../ui/home/providers/home_scope_providers.dart';
import '../../../ui/provider/database_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/message_optimize.dart';
import '../../action_button.dart';
import '../../dialog.dart';
import '../../interactive_decorated_box.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_day_time.dart';
import '../message_style.dart';
import 'unknown_message.dart';

class TranscriptMessagesWatcher {
  const TranscriptMessagesWatcher(this.watchMessages);

  final Stream<List<MessageItem>> Function() watchMessages;
}

final transcriptMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageItem>, String>((
      ref,
      transcriptMessageId,
    ) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <MessageItem>[]);
      }
      return _watchTranscriptMessages(database, transcriptMessageId);
    });

final transcriptMessagesWatcherProvider = Provider.autoDispose
    .family<TranscriptMessagesWatcher, String>((
      ref,
      transcriptMessageId,
    ) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return TranscriptMessagesWatcher(
          () => const Stream<List<MessageItem>>.empty(),
        );
      }
      return TranscriptMessagesWatcher(
        () => _watchTranscriptMessages(database, transcriptMessageId),
      );
    });

Stream<List<MessageItem>> _watchTranscriptMessages(
  Database database,
  String transcriptMessageId,
) => database.transcriptMessageDao
    .transactionMessageItem(transcriptMessageId)
    .watchWithStream(
      eventStreams: [
        DataBaseEventBus.instance.watchUpdateTranscriptMessageStream(
          transcriptIds: [transcriptMessageId],
        ),
        DataBaseEventBus.instance.updateAssetStream,
        DataBaseEventBus.instance.updateStickerStream,
      ],
      duration: kDefaultThrottleDuration,
    )
    .map(
      (list) => list
          .map(
            (transcriptMessageItem) => transcriptMessageItem.messageItem,
          )
          .toList(),
    );

class TranscriptMessageWidget extends HookConsumerWidget {
  const TranscriptMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final content = useMessageConverter(
      converter: (state) => state.content ?? '',
    );
    final transcriptMinimals = useMemoized<List<TranscriptMinimal>?>(() {
      try {
        final json = jsonDecode(content);
        return (json as List<dynamic>)
            .map(
              (json) =>
                  TranscriptMinimal.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } catch (error) {
        e('TranscriptMessageWidget.build $error');
        e('parse json failed: $content');
        return null;
      }
    }, [content]);

    final isCurrentUser = useIsCurrentUser();

    if (transcriptMinimals == null) {
      e('TranscriptMessageWidget: transcriptMinimals is null');
      return const UnknownMessage();
    }

    return HookBuilder(
      builder: (context) {
        final previews = useMemoized(
          () => transcriptMinimals
              .map(
                (transcriptMinimal) =>
                    messagePreviewOptimize(
                      null,
                      transcriptMinimal.category,
                      transcriptMinimal.content,
                    ) ??
                    '',
              )
              .toList(),
          [transcriptMinimals],
        );

        assert(
          previews.isEmpty || previews.length == transcriptMinimals.length,
        );

        final transcriptTexts = useMemoized(
          () =>
              List.generate(
                math.min(transcriptMinimals.length, 4),
                (index) => index,
              ).map(
                (i) =>
                    '${transcriptMinimals[i].name}: ${previews.isEmpty ? '' : previews[i]}'
                        .overflow,
              ),
          [transcriptMinimals, previews],
        );

        return MessageBubble(
          padding: const EdgeInsets.only(top: 4, bottom: 2, right: 2, left: 2),
          child: InteractiveDecoratedBox(
            onTap: () async {
              final audioService = ref.read(audioMessagePlayServiceProvider);
              final message = context.message;
              await showMixinDialog(
                context: context,
                padding: const EdgeInsets.symmetric(vertical: 80),
                backgroundColor: theme.chatBackground,
                child: TranscriptPage(
                  transcriptMessage: message,
                ),
              );

              if (audioService.playing) {
                audioService.stop();
              }
            },
            child: SizedBox(
              width: 260,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              l10n.transcript,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: context.messageStyle.primaryFontSize,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                color: Color.fromRGBO(0, 0, 0, 0.2),
                              ),
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                Resources.assetsImagesPostDetailSvg,
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: transcriptTexts
                              .map(
                                (text) => Text(
                                  text,
                                  style: TextStyle(
                                    color: theme.secondaryText,
                                    fontSize:
                                        context.messageStyle.tertiaryFontSize,
                                  ),
                                  maxLines: 1,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 2,
                    right: isCurrentUser ? 1 : 2,
                    child: const DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.3),
                        shape: StadiumBorder(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 5,
                        ),
                        child: MessageDatetimeAndStatus(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TranscriptPage extends HookConsumerWidget {
  const TranscriptPage({
    required this.transcriptMessage,
    super.key,
  });

  final MessageItem transcriptMessage;

  static MessageItem? of(BuildContext context) => context
      .findAncestorWidgetOfExactType<TranscriptPage>()
      ?.transcriptMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useMemoized(ScrollController.new);
    final listKey = useMemoized(
      () => GlobalKey(debugLabel: 'transcript_list_key'),
    );

    return TickerMode(
      enabled: ModalRoute.of(context)?.isCurrent ?? true,
      child: _TranscriptPageScope(
        transcriptMessageId: transcriptMessage.messageId,
        listKey: listKey,
        scrollController: scrollController,
      ),
    );
  }
}

class _TranscriptPageScope extends HookConsumerWidget {
  const _TranscriptPageScope({
    required this.transcriptMessageId,
    required this.listKey,
    required this.scrollController,
  });

  final String transcriptMessageId;
  final GlobalKey listKey;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final list =
        ref.watch(transcriptMessagesProvider(transcriptMessageId)).value ??
        <MessageItem>[];

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 600,
        minWidth: 600,
        minHeight: 800,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActionButton(
                      name: Resources.assetsImagesIcCloseSvg,
                      color: theme.icon,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    child: Text(
                      l10n.transcript,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Expanded(
            child: MessageDayTimeViewportWidget.singleList(
              listKey: listKey,
              scrollController: scrollController,
              child: ListView.builder(
                controller: scrollController,
                key: listKey,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) => MessageItemWidget(
                  prev: list.getOrNull(index - 1),
                  message: list[index],
                  next: list.getOrNull(index + 1),
                  isTranscriptPage: true,
                ),
                itemCount: list.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
