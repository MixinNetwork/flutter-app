import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../../blaze/vo/transcript_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../ui/home/bloc/blink_cubit.dart';
import '../../../ui/home/chat_page.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../../action_button.dart';
import '../../dialog.dart';
import '../../interacter_decorated_box.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class TranscriptMessageWidget extends HookWidget {
  const TranscriptMessageWidget({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final transcriptMinimals = useMemoized<List<TranscriptMinimal>>(() {
      final json = jsonDecode(message.content ?? '');
      if (json is List<dynamic>) {
        return json
            .map((json) =>
                TranscriptMinimal.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    });

    final previews = useMemoizedFuture(
            () => Future.wait(transcriptMinimals
                .map((transcriptMinimal) => messagePreviewOptimize(
                      null,
                      transcriptMinimal.category,
                      transcriptMinimal.content,
                    ))),
            [],
            keys: [transcriptMinimals]).data ??
        [];

    assert(previews.isEmpty || previews.length == transcriptMinimals.length);

    final transcriptTexts = useMemoized(
        () => List.generate(
            min(transcriptMinimals.length, 4),
            (index) =>
                index).map((i) =>
            '${transcriptMinimals[i].name}: ${previews.isEmpty ? '' : previews[i]}'),
        [
          transcriptMinimals,
          previews,
        ]);

    return MessageBubble(
      messageId: message.messageId,
      quoteMessageId: message.quoteId,
      quoteMessageContent: message.quoteContent,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 2,
        right: 2,
        left: 2,
      ),
      child: InteractableDecoratedBox(
        onTap: () => showMixinDialog(
            context: context,
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: TranscriptPage(
              messageId: message.messageId,
              conversationId: message.conversationId,
            )),
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
                          context.l10n.chatTranscript,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: MessageItemWidget.primaryFontSize,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
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
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: transcriptTexts
                          .map(
                            (text) => Text(
                              text,
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: MessageItemWidget.tertiaryFontSize,
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
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                    shape: StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 5,
                    ),
                    child: MessageDatetimeAndStatus(
                      isCurrentUser: isCurrentUser,
                      color: Colors.white,
                      message: message,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranscriptPage extends HookWidget {
  const TranscriptPage({
    Key? key,
    required this.messageId,
    required this.conversationId,
  }) : super(key: key);
  final String messageId;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final list = useMemoizedStream(() => context.database.transcriptMessageDao
            .transactionMessageItem(messageId)
            .watch()
            .map(
              (list) => list
                  .map((transcriptMessageItem) =>
                      transcriptMessageItem.messageItem)
                  .toList(),
            )).data ??
        <MessageItem>[];

    final chatSideCubit = useBloc(() => ChatSideCubit());
    final searchConversationKeywordCubit = useBloc(
      () => SearchConversationKeywordCubit(chatSideCubit: chatSideCubit),
    );

    final tickerProvider = useSingleTickerProvider();
    final blinkCubit = useBloc(
      () => BlinkCubit(
        tickerProvider,
        context.theme.accent.withOpacity(0.5),
      ),
    );

    return ColoredBox(
      color: context.theme.chatBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          minWidth: 600,
          minHeight: 800,
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: searchConversationKeywordCubit,
            ),
            BlocProvider.value(
              value: blinkCubit,
            ),
          ],
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
                          color: context.theme.icon,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        child: Text(
                          context.l10n.chatTranscript,
                          style: TextStyle(
                            color: context.theme.text,
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
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) =>
                      MessageItemWidget(
                    prev: list.getOrNull(index - 1),
                    message: list[index],
                    next: list.getOrNull(index + 1),
                  ),
                  itemCount: list.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
