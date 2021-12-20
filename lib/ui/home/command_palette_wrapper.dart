import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/resources.dart';
import '../../db/extension/conversation.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/search_text_field.dart';
import 'bloc/conversation_cubit.dart';
import 'conversation_page.dart';
import 'intent.dart';

const _kItemHeight = 72.0;

void _jumpToPosition(ScrollController scrollController, int length, int index) {
  if (!scrollController.hasClients) return;

  final viewportDimension = scrollController.position.viewportDimension;
  final offset = scrollController.offset;

  final maxScrollExtent = length * _kItemHeight;
  final maxValidScrollExtent = maxScrollExtent - viewportDimension;

  final startIndex = offset ~/ _kItemHeight;
  final endIndex = (offset + viewportDimension - _kItemHeight) ~/ _kItemHeight;

  if (index <= startIndex) {
    final pixel = (_kItemHeight * index - viewportDimension + _kItemHeight * 2)
        .clamp(0, maxValidScrollExtent)
        .toDouble();
    scrollController.animateTo(pixel,
        duration: const Duration(milliseconds: 150), curve: Curves.easeIn);
  } else if (index >= endIndex) {
    final pixel = (_kItemHeight * index - _kItemHeight)
        .clamp(0, maxValidScrollExtent)
        .toDouble();
    scrollController.animateTo(pixel,
        duration: const Duration(milliseconds: 150), curve: Curves.easeIn);
  }
}

class CommandPaletteWrapper extends StatelessWidget {
  const CommandPaletteWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        shortcuts: {
          SingleActivator(
            LogicalKeyboardKey.keyK,
            meta: kPlatformIsDarwin,
            control: !kPlatformIsDarwin,
          ): const _ToggleCommandPaletteIntent(),
        },
        actions: {
          _ToggleCommandPaletteIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) => showMixinDialog(
              context: context,
              child: const CommandPalettePage(),
            ),
          )
        },
        child: child,
      );
}

class _ToggleCommandPaletteIntent extends Intent {
  const _ToggleCommandPaletteIntent();
}

class CommandPalettePage extends HookWidget {
  const CommandPalettePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final textEditingController = useTextEditingController();
    final stream = useValueNotifierConvertSteam(textEditingController);
    final keyword = useMemoizedStream(() => stream
            .map((event) => event.text)
            .throttleTime(
              const Duration(milliseconds: 100),
              trailing: true,
              leading: false,
            )
            .distinct()).data ??
        '';

    final users = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<User>[]);
          }
          return context.database.userDao
              .fuzzySearchUser(
                  id: context.accountServer.userId,
                  username: keyword,
                  identityNumber: keyword)
              .watchThrottle(kSlowThrottleDuration);
        }, keys: [keyword]).data ??
        [];

    final conversations = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<SearchConversationItem>[]);
          }
          return context.database.conversationDao
              .fuzzySearchConversation(keyword, 32)
              .watchThrottle(kSlowThrottleDuration);
        }, keys: [keyword]).data ??
        [];

    final selectedIndex = useState<int>(0);

    final ids = useMemoized(
        () => [
              ...users.map((e) => e.userId),
              ...conversations.map((e) => e.conversationId)
            ],
        [users, conversations]);

    useEffect(() {
      selectedIndex.value = 0;
    }, [ids]);

    final next = useCallback(() {
      final newValue =
          min(selectedIndex.value + 1, users.length + conversations.length - 1);
      if (selectedIndex.value == newValue) return;
      selectedIndex.value = newValue;
      _jumpToPosition(scrollController, users.length + conversations.length,
          selectedIndex.value);
    }, [ids]);

    final prev = useCallback(() {
      final newValue = max(selectedIndex.value - 1, 0);
      if (selectedIndex.value == newValue) return;
      selectedIndex.value = newValue;
      _jumpToPosition(scrollController, users.length + conversations.length,
          selectedIndex.value);
    }, [ids]);

    final select = useCallback(([int? index]) {
      if (index != null) {
        selectedIndex.value = index;
      }
      if (selectedIndex.value < users.length) {
        ConversationCubit.selectUser(context, ids[selectedIndex.value]);
      } else if ((selectedIndex.value - users.length) < conversations.length) {
        ConversationCubit.selectConversation(context, ids[selectedIndex.value]);
      } else {
        return;
      }
      Navigator.pop(context);
    }, [ids]);

    return FocusableActionDetector(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const ListSelectionPrevIntent(),
        const SingleActivator(LogicalKeyboardKey.tab):
            const ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const ListSelectionSelectedIntent(),
        if (kPlatformIsDarwin) ...{
          const SingleActivator(
            LogicalKeyboardKey.keyN,
            control: true,
          ): const ListSelectionNextIntent(),
          const SingleActivator(
            LogicalKeyboardKey.keyP,
            control: true,
          ): const ListSelectionPrevIntent(),
        }
      },
      actions: {
        ListSelectionNextIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => next(),
        ),
        ListSelectionPrevIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => prev(),
        ),
        ListSelectionSelectedIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => select(),
        ),
      },
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 400,
            maxWidth: 480,
            maxHeight: 600,
            minHeight: 400,
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 30)
                        .copyWith(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchTextField(
                        controller: textEditingController,
                        autofocus: true,
                      ),
                    ),
                    const MixinCloseButton(),
                  ],
                ),
              ),
              if (users.isEmpty && conversations.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          Resources.assetsImagesEmptyFileSvg,
                          height: 80,
                          width: 80,
                          color: context.theme.secondaryText,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.noResults,
                          style: TextStyle(
                            color: context.theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      if (users.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final user = users[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: SearchItem(
                                  selected: selectedIndex.value == index,
                                  avatar: AvatarWidget(
                                    name: user.fullName ?? '?',
                                    userId: user.userId,
                                    size: ConversationPage
                                        .conversationItemAvatarSize,
                                    avatarUrl: user.avatarUrl,
                                  ),
                                  name: user.fullName ?? '?',
                                  trailing: VerifiedOrBotWidget(
                                    verified: user.isVerified,
                                    isBot: user.appId != null,
                                  ),
                                  keyword: keyword,
                                  onTap: () => select(index),
                                ),
                              );
                            },
                            childCount: users.length,
                          ),
                        ),
                      if (conversations.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final conversation = conversations[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: SearchItem(
                                  selected: selectedIndex.value ==
                                      (users.length + index),
                                  avatar: ConversationAvatarWidget(
                                    conversationId: conversation.conversationId,
                                    fullName: conversation.validName,
                                    groupIconUrl: conversation.groupIconUrl,
                                    avatarUrl: conversation.avatarUrl,
                                    category: conversation.category,
                                    size: ConversationPage
                                        .conversationItemAvatarSize,
                                    userId: conversation.ownerId,
                                  ),
                                  name: conversation.validName,
                                  trailing: VerifiedOrBotWidget(
                                    verified: conversation.isVerified,
                                    isBot: conversation.appId != null,
                                  ),
                                  keyword: keyword,
                                  onTap: () => select(users.length + index),
                                ),
                              );
                            },
                            childCount: conversations.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
