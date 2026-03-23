import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../constants/resources.dart';
import '../../db/database.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/conversation/search_list.dart';
import '../../ui/home/intent.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/database_provider.dart';
import '../../ui/provider/recent_conversation_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
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
const _kBottomPadding = 22.0;

void _jumpToPosition(ScrollController scrollController, int length, int index) {
  if (!scrollController.hasClients) return;

  final viewportDimension = scrollController.position.viewportDimension;
  const itemExtent = _kItemHeight;
  final contentHeight = length * itemExtent + _kBottomPadding;
  final maxScrollExtent = contentHeight - viewportDimension;

  final currentOffset = scrollController.offset;
  final itemOffset = index * itemExtent;
  final itemEndOffset = itemOffset + itemExtent;

  final isFullyVisible =
      itemOffset >= currentOffset &&
      itemEndOffset <= (currentOffset + viewportDimension);

  if (!isFullyVisible) {
    final middleOffset = itemOffset - (viewportDimension - itemExtent) / 2;

    final remainingContentHeight = contentHeight - itemEndOffset;
    final halfViewport = (viewportDimension - itemExtent) / 2;

    final targetOffset = remainingContentHeight < halfViewport
        ? maxScrollExtent
        : middleOffset.clamp(0.0, maxScrollExtent);

    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
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
  required WidgetRef ref,
  required String keyword,
  required Database database,
  required String selfUserId,
}) {
  final users =
      useMemoizedStream<List<SearchItem>>(() {
        if (keyword.trim().isEmpty) {
          return Stream.value([]);
        }
        return database.userDao
            .fuzzySearchUserItem(keyword, selfUserId)
            .watchWithStream(
              eventStreams: [DataBaseEventBus.instance.updateUserIdsStream],
              duration: kVerySlowThrottleDuration,
            );
      }, keys: [keyword]).data ??
      [];

  final recentConversationIds = ref.watch(recentConversationIDsProvider);

  final conversations =
      useMemoizedStream<List<SearchItem>>(() {
        if (keyword.trim().isEmpty) {
          if (recentConversationIds.isEmpty) {
            return Stream.value([]);
          }

          return database.conversationDao
              .fuzzySearchConversationItemByIds(recentConversationIds)
              .watchWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateConversationStream(
                    recentConversationIds,
                  ),
                ],
                duration: kSlowThrottleDuration,
              );
        }
        return database.conversationDao
            .fuzzySearchConversationItem(keyword)
            .watchWithStream(
              eventStreams: [
                DataBaseEventBus.instance.updateConversationIdStream,
              ],
              duration: kSlowThrottleDuration,
            );
      }, keys: [keyword, recentConversationIds]).data ??
      [];

  final items = useMemoized(() {
    final allItems = [...users, ...conversations];
    return allItems..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }, [users, conversations]);

  return _SearchState(users: users, conversations: conversations, items: items);
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
  required ProviderContainer container,
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

  final select = useCallback<void Function([int?])>(([index]) {
    if (index != null) {
      selectedIndex.value = index;
    }

    if (items.isEmpty) return;

    final item = items[selectedIndex.value];
    if (item.type == 'GROUP' || item.type == 'CONTACT') {
      ConversationStateNotifier.selectConversation(container, context, item.id);
    } else {
      ConversationStateNotifier.selectUser(container, context, item.id);
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
  CommandPaletteAction(this.context, this.container);

  final BuildContext context;
  final ProviderContainer container;
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
    final database = ref.read(databaseProvider).requireValue;
    final selfUserId = ref.read(accountServerProvider).requireValue.userId;
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final scrollController = useScrollController();
    final textEditingController = useTextEditingController();
    final stream = useValueNotifierConvertSteam(textEditingController);
    final keyword =
        useMemoizedStream(
          () => stream
              .map((event) => event.text)
              .throttleTime(const Duration(milliseconds: 100))
              .distinct(),
        ).data ??
        '';

    final searchState = _useSearchState(
      ref: ref,
      keyword: keyword,
      database: database,
      selfUserId: selfUserId,
    );

    final navigationState = _useNavigationState(
      scrollController: scrollController,
      items: searchState.items,
      context: context,
      container: ref.container,
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
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              const ListSelectionNextIntent(),
          const SingleActivator(LogicalKeyboardKey.keyP, control: true):
              const ListSelectionPrevIntent(),
        },
      },
      actions: {
        ListSelectionNextIntent: CallbackAction<Intent>(
          onInvoke: (intent) => navigationState.next(),
        ),
        ListSelectionPrevIntent: CallbackAction<Intent>(
          onInvoke: (intent) => navigationState.prev(),
        ),
        ListSelectionSelectedIntent: CallbackAction<Intent>(
          onInvoke: (intent) => navigationState.select(),
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
                            theme.secondaryText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.noResults,
                          style: TextStyle(
                            color: theme.secondaryText,
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
                        delegate: SliverChildBuilderDelegate((
                          context,
                          index,
                        ) {
                          final item = searchState.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SearchItemWidget(
                              selected: navigationState.selectedIndex == index,
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
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
                        }, childCount: searchState.items.length),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: _kBottomPadding),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
