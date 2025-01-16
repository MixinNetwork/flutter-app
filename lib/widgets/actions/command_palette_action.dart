import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../constants/resources.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/conversation/search_list.dart';
import '../../ui/home/intent.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/recent_conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../conversation/badges_widget.dart';
import '../dialog.dart';
import '../search_text_field.dart';
import 'actions.dart';

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

class _SearchState {
  const _SearchState({
    required this.users,
    required this.conversations,
    required this.items,
  });

  final List<SearchItem> users;
  final List<SearchItem> conversations;
  final List<SearchItem> items;
}

_SearchState _useSearchState({
  required BuildContext context,
  required WidgetRef ref,
  required String keyword,
}) {
  final users = useMemoizedStream<List<SearchItem>>(() {
        if (keyword.trim().isEmpty) {
          return Stream.value([]);
        }
        return context.database.userDao
            .fuzzySearchUserItem(keyword, context.accountServer.userId)
            .watchWithStream(
          eventStreams: [DataBaseEventBus.instance.updateUserIdsStream],
          duration: kVerySlowThrottleDuration,
        );
      }, keys: [keyword]).data ??
      [];

  final recentConversationIds = ref.watch(recentConversationIDsProvider);

  final conversations = useMemoizedStream<List<SearchItem>>(() {
        if (keyword.trim().isEmpty) {
          if (recentConversationIds.isEmpty) {
            return Stream.value([]);
          }

          return context.database.conversationDao
              .fuzzySearchConversationItemByIds(recentConversationIds)
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance
                  .watchUpdateConversationStream(recentConversationIds)
            ],
            duration: kSlowThrottleDuration,
          );
        }
        return context.database.conversationDao
            .fuzzySearchConversationItem(keyword)
            .watchWithStream(
          eventStreams: [DataBaseEventBus.instance.updateConversationIdStream],
          duration: kSlowThrottleDuration,
        );
      }, keys: [keyword, recentConversationIds]).data ??
      [];

  final items = useMemoized(() {
    final allItems = [...users, ...conversations];
    return allItems..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }, [users, conversations]);

  return _SearchState(
    users: users,
    conversations: conversations,
    items: items,
  );
}

class _NavigationState {
  const _NavigationState({
    required this.selectedIndex,
    required this.next,
    required this.prev,
    required this.select,
  });

  final int selectedIndex;
  final void Function() next;
  final void Function() prev;
  final void Function([int? index]) select;
}

_NavigationState _useNavigationState({
  required ScrollController scrollController,
  required List<SearchItem> items,
  required BuildContext context,
}) {
  final selectedIndex = useState<int>(0);

  useEffect(() {
    selectedIndex.value = 0;
  }, [items]);

  final next = useCallback(() {
    final newValue = min(selectedIndex.value + 1, items.length - 1);
    if (selectedIndex.value == newValue) return;
    selectedIndex.value = newValue;
    _jumpToPosition(scrollController, items.length, selectedIndex.value);
  }, [items]);

  final prev = useCallback(() {
    final newValue = max(selectedIndex.value - 1, 0);
    if (selectedIndex.value == newValue) return;
    selectedIndex.value = newValue;
    _jumpToPosition(scrollController, items.length, selectedIndex.value);
  }, [items]);

  final select = useCallback(([int? index]) {
    if (index != null) {
      selectedIndex.value = index;
    }

    if (items.isEmpty) return;

    final item = items[selectedIndex.value];
    if (item.type == 'GROUP' || item.type == 'CONTACT') {
      ConversationStateNotifier.selectConversation(context, item.id);
    } else {
      ConversationStateNotifier.selectUser(context, item.id);
    }
    Navigator.pop(context);
  }, [items]);

  return _NavigationState(
    selectedIndex: selectedIndex.value,
    next: next,
    prev: prev,
    select: select,
  );
}

class CommandPaletteAction extends Action<ToggleCommandPaletteIntent> {
  CommandPaletteAction(this.context);

  final BuildContext context;
  static bool _commandPaletteShowing = false;

  @override
  Object? invoke(ToggleCommandPaletteIntent intent) {
    if (_commandPaletteShowing) {
      return null;
    }
    _commandPaletteShowing = true;
    showMixinDialog(
      context: context,
      child: const CommandPalettePage(),
    ).whenComplete(() {
      _commandPaletteShowing = false;
    });
  }
}

class CommandPalettePage extends HookConsumerWidget {
  const CommandPalettePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final textEditingController = useTextEditingController();
    final stream = useValueNotifierConvertSteam(textEditingController);
    final keyword = useMemoizedStream(() => stream
            .map((event) => event.text)
            .throttleTime(const Duration(milliseconds: 100))
            .distinct()).data ??
        '';

    final searchState = _useSearchState(
      context: context,
      ref: ref,
      keyword: keyword,
    );

    final navigationState = _useNavigationState(
      scrollController: scrollController,
      items: searchState.items,
      context: context,
    );

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
          onInvoke: (Intent intent) => navigationState.next(),
        ),
        ListSelectionPrevIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => navigationState.prev(),
        ),
        ListSelectionSelectedIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => navigationState.select(),
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
                padding: const EdgeInsets.only(
                  right: 20,
                  left: 20,
                  top: 20,
                  bottom: 10,
                ),
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
              if (searchState.users.isEmpty &&
                  searchState.conversations.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          Resources.assetsImagesEmptyFileSvg,
                          height: 80,
                          width: 80,
                          colorFilter: ColorFilter.mode(
                              context.theme.secondaryText, BlendMode.srcIn),
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
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final item = searchState.items[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: SearchItemWidget(
                                selected:
                                    navigationState.selectedIndex == index,
                                margin: EdgeInsets.zero,
                                padding: const EdgeInsets.all(14),
                                avatar: item.type == 'GROUP'
                                    ? ConversationAvatarWidget(
                                        conversationId: item.id,
                                        size: 40,
                                        category: ConversationCategory.group,
                                      )
                                    : AvatarWidget(
                                        name: item.name,
                                        userId: item.id,
                                        size: 40,
                                        avatarUrl: item.avatarUrl,
                                      ),
                                name: item.name ?? '',
                                trailing: BadgesWidget(
                                  verified: item.isVerified,
                                  isBot: item.type == 'BOT',
                                  membership: item.membership,
                                ),
                                keyword: keyword.trim(),
                                onTap: () => navigationState.select(index),
                              ),
                            );
                          },
                          childCount: searchState.items.length,
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
