import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../constants/brightness_theme_data.dart';
import '../../constants/constants.dart';
import '../../constants/resources.dart';
import '../../crypto/uuid/uuid.dart';
import '../../db/dao/conversation_dao.dart';
import '../../db/mixin_database.dart';
import '../../enum/encrypt_category.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/database_provider.dart';
import '../../ui/provider/multi_auth_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../action_button.dart';
import '../avatar_view/avatar_view.dart';
import '../conversation/badges_widget.dart';
import '../dialog.dart';
import '../high_light_text.dart';
import '../interactive_decorated_box.dart';
import 'controllers/conversation_filter_controller.dart';

String _getConversationName(dynamic item) {
  if (item is ConversationItem) return item.validName;
  if (item is User) return item.fullName ?? '?';
  throw ArgumentError('must be ConversationItem or User');
}

String _getConversationId(dynamic item, String selfUserId) {
  if (item is ConversationItem) return item.conversationId;
  if (item is User) {
    return generateConversationId(item.userId, selfUserId);
  }
  throw ArgumentError('must be ConversationItem or User');
}

String? _getUserId(dynamic item) {
  if (item is ConversationItem && !item.isGroupConversation) {
    return item.ownerId;
  }
  if (item is User) return item.userId;
}

EncryptCategory _getEncryptedCategory(dynamic item, Map<String, App> map) {
  bool isEncrypted(String appId) {
    final app = map[appId];
    return app != null && app.capabilities?.contains('ENCRYPTED') == true;
  }

  if (item is ConversationItem) {
    // ignore: cast_nullable_to_non_nullable
    if (item.ownerId != null && isEncrypted(item.ownerId as String)) {
      return EncryptCategory.encrypted;
    }
    return item.isBotConversation
        ? EncryptCategory.plain
        : EncryptCategory.signal;
  }
  if (item is User) {
    if (isEncrypted(item.userId)) return EncryptCategory.encrypted;
    return item.isBot ? EncryptCategory.plain : EncryptCategory.signal;
  }
  throw ArgumentError('must be ConversationItem or User');
}

Widget _getAvatarWidget(dynamic item) {
  if (item is ConversationItem) return item.avatarWidget;
  if (item is User) return item.avatarWidget;
  throw ArgumentError('must be ConversationItem or User');
}

extension _AvatarUser on User {
  Widget get avatarWidget => AvatarWidget(
    size: 50,
    avatarUrl: avatarUrl,
    name: fullName,
    userId: userId,
  );
}

extension _AvatarConversationItem on ConversationItem {
  Widget get avatarWidget =>
      ConversationAvatarWidget(size: 50, conversation: this);
}

Future<List<ConversationSelector>?> showConversationSelector({
  required BuildContext context,
  required bool singleSelect,
  required String title,
  required bool onlyContact,
  Iterable<String> filteredIds = const [],
  bool allowEmpty = false,
  List<ConversationSelector> initSelected = const [],
  String? confirmedText,
  Widget? action,
  int? maxSelect,
}) => showMixinDialog<List<ConversationSelector>?>(
  context: context,
  child: _ConversationSelector(
    title: title,
    singleSelect: singleSelect,
    onlyContact: onlyContact,
    initSelected: initSelected,
    filteredIds: filteredIds,
    allowEmpty: allowEmpty,
    confirmedText: confirmedText,
    action: action,
    maxSelect: maxSelect,
  ),
);

class ConversationSelector with EquatableMixin {
  const ConversationSelector({
    required this.conversationId,
    required this.userId,
    this.encryptCategory,
  });

  final String conversationId;
  final String? userId;
  final EncryptCategory? encryptCategory;

  @override
  List<Object?> get props => [conversationId, userId, encryptCategory];

  static ConversationSelector init(
    dynamic item,
    String selfUserId,
    Map<String, App> map,
  ) => ConversationSelector(
    conversationId: _getConversationId(item, selfUserId),
    userId: _getUserId(item),
    encryptCategory: _getEncryptedCategory(item, map),
  );
}

class _ConversationSelectorAppsArgs with EquatableMixin {
  const _ConversationSelectorAppsArgs({
    required this.database,
    required this.appIds,
  });

  final MixinDatabase database;
  final List<String> appIds;

  @override
  List<Object?> get props => [database, appIds];
}

class _SelectedItemsNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => const [];

  void toggle(dynamic item, {int? maxSelect}) {
    final list = [...state];
    if (list.contains(item)) {
      list.remove(item);
    } else {
      if (maxSelect != null && list.length >= maxSelect) {
        w('max select reached: $maxSelect');
        return;
      }
      list.add(item);
    }
    state = list;
  }

  void replace(List<dynamic> items) => state = items;
}

class _BootstrapSelectionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() => state = true;
}

final _selectedItemsProvider =
    NotifierProvider.autoDispose<_SelectedItemsNotifier, List<dynamic>>(
      _SelectedItemsNotifier.new,
    );

final _bootstrapSelectionProvider =
    NotifierProvider.autoDispose<_BootstrapSelectionNotifier, bool>(
      _BootstrapSelectionNotifier.new,
    );

final _conversationSelectorAppsProvider = FutureProvider.autoDispose
    .family<Map<String, App>, _ConversationSelectorAppsArgs>((ref, args) async {
      final list = await args.database.appDao.appInIds(args.appIds).get();
      return {for (final e in list) e.appId: e};
    });

class _ConversationSelector extends HookConsumerWidget {
  const _ConversationSelector({
    required this.singleSelect,
    required this.title,
    required this.onlyContact,
    this.initSelected = const [],
    this.filteredIds = const [],
    this.allowEmpty = false,
    this.confirmedText,
    this.action,
    this.maxSelect,
  });

  final String title;
  final bool singleSelect;
  final bool onlyContact;
  final List<ConversationSelector> initSelected;
  final Iterable<String> filteredIds;
  final bool allowEmpty;
  final String? confirmedText;
  final Widget? action;
  final int? maxSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final selfUserId =
        ref.read(authAccountProvider)?.userId ?? accountServer.userId;
    final args = ConversationFilterArgs(
      accountServer: accountServer,
      onlyContact: onlyContact,
      filteredIds: filteredIds.toList(growable: false),
    );
    final conversationFilterState = ref.watch(
      conversationFilterStateProvider(args),
    );
    final selected = ref.watch(_selectedItemsProvider);
    final selectedNotifier = ref.read(_selectedItemsProvider.notifier);

    ref.listen<ConversationFilterState>(
      conversationFilterStateProvider(args),
      (previous, next) {
        if (ref.read(_bootstrapSelectionProvider)) return;
        if (!next.initialized) return;

        final conversationIds = initSelected
            .map((e) => e.conversationId)
            .toSet();
        final userIds = initSelected.map((e) => e.userId).toSet();
        selectedNotifier.replace([
          ...next.recentConversations.where(
            (element) => conversationIds.contains(element.conversationId),
          ),
          ...next.friends.where((element) => userIds.contains(element.userId)),
          ...next.bots.where((element) => userIds.contains(element.userId)),
        ]);
        ref.read(_bootstrapSelectionProvider.notifier).markReady();
      },
    );

    final appMap =
        ref
            .watch(
              _conversationSelectorAppsProvider(
                _ConversationSelectorAppsArgs(
                  database: database.mixinDatabase,
                  appIds: conversationFilterState.appIds.toList(
                    growable: false,
                  ),
                ),
              ),
            )
            .value ??
        const <String, App>{};

    useEffect(
      () => ref.listenManual<List<dynamic>>(_selectedItemsProvider, (
        previous,
        event,
      ) {
        if (event.isNotEmpty && singleSelect) {
          final item = event.first;
          Navigator.pop(context, [
            ConversationSelector.init(item, selfUserId, appMap),
          ]);
        }
      }).close,
      [singleSelect, appMap, selfUserId],
    );

    const boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 480,
        height: 600,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionButton(
                        name: Resources.assetsImagesIcCloseSvg,
                        color: brightnessTheme.icon,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: brightnessTheme.text,
                              fontSize: 16,
                            ),
                          ),
                          if (!singleSelect)
                            Text(
                              '${selected.length} / ${maxSelect ?? conversationFilterState.recentConversations.length + conversationFilterState.friends.length + conversationFilterState.bots.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: brightnessTheme.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child:
                          action ??
                          (!singleSelect && (allowEmpty || selected.isNotEmpty)
                              ? MixinButton(
                                  backgroundTransparent: true,
                                  padding: const EdgeInsets.all(8),
                                  onTap: () => Navigator.pop(
                                    context,
                                    selected
                                        .map(
                                          (item) => ConversationSelector.init(
                                            item,
                                            selfUserId,
                                            appMap,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  child: Text(
                                    confirmedText ?? l10n.next,
                                  ),
                                )
                              : const SizedBox()),
                    ),
                  ),
                ],
              ),
            ),
            _FilterTextField(
              conversationFilterArgs: args,
            ),
            AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
              child: singleSelect || selected.isEmpty
                  ? const SizedBox(height: 8)
                  : SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemBuilder: (context, index) => SizedBox(
                          width: 66,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              Stack(
                                children: [
                                  _getAvatarWidget(selected[index]),
                                  _AvatarSmallCloseIcon(
                                    onTap: () => selectedNotifier.toggle(
                                      selected[index],
                                      maxSelect: maxSelect,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getConversationName(selected[index]),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: brightnessTheme.text,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 4),
                        itemCount: selected.length,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomScrollView(
                  slivers: [
                    if (conversationFilterState.recentConversations.isNotEmpty)
                      _Section(
                        title: l10n.recentChats,
                        count:
                            conversationFilterState.recentConversations.length,
                        hoveringColor: brightnessTheme.listSelected,
                        builder: (context, index) {
                          final item = conversationFilterState
                              .recentConversations[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: brightnessTheme.listSelected,
                            onTap: () => selectedNotifier.toggle(
                              item,
                              maxSelect: maxSelect,
                            ),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.validName,
                              verified: item.ownerVerified,
                              isBot: item.isBotConversation,
                              membership: item.membership,
                              selected: selected.any(
                                (element) =>
                                    _getConversationId(element, selfUserId) ==
                                    _getConversationId(item, selfUserId),
                              ),
                              showSelector: !singleSelect,
                            ),
                          );
                        },
                      ),
                    if (conversationFilterState.friends.isNotEmpty)
                      _Section(
                        title: l10n.contactTitle,
                        count: conversationFilterState.friends.length,
                        hoveringColor: brightnessTheme.listSelected,
                        builder: (context, index) {
                          final item = conversationFilterState.friends[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: brightnessTheme.listSelected,
                            onTap: () => selectedNotifier.toggle(
                              item,
                              maxSelect: maxSelect,
                            ),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.fullName ?? '',
                              verified: item.isVerified ?? false,
                              isBot: item.appId != null,
                              membership: item.membership,
                              showSelector: !singleSelect,
                              selected: selected.any(
                                (element) =>
                                    _getConversationId(element, selfUserId) ==
                                    _getConversationId(item, selfUserId),
                              ),
                            ),
                          );
                        },
                      ),
                    if (conversationFilterState.bots.isNotEmpty)
                      _Section(
                        title: l10n.bots,
                        count: conversationFilterState.bots.length,
                        hoveringColor: brightnessTheme.listSelected,
                        builder: (context, index) {
                          final item = conversationFilterState.bots[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: brightnessTheme.listSelected,
                            onTap: () => selectedNotifier.toggle(
                              item,
                              maxSelect: maxSelect,
                            ),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.fullName!,
                              verified: item.isVerified ?? false,
                              isBot: item.appId != null,
                              membership: item.membership,
                              showSelector: !singleSelect,
                              selected: selected.any(
                                (element) =>
                                    _getConversationId(element, selfUserId) ==
                                    _getConversationId(item, selfUserId),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTextField extends HookConsumerWidget {
  const _FilterTextField({required this.conversationFilterArgs});

  final ConversationFilterArgs conversationFilterArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final conversationFilterState = ref.watch(
      conversationFilterStateProvider(conversationFilterArgs),
    );
    final isTextEmpty = conversationFilterState.keyword?.isEmpty ?? true;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 8, right: 24, left: 24),
      decoration: BoxDecoration(
        color: brightnessTheme.background,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      alignment: Alignment.center,
      child: Stack(
        children: [
          TextField(
            onChanged: (string) => ref
                .read(
                  conversationFilterStateProvider(
                    conversationFilterArgs,
                  ).notifier,
                )
                .setKeyword(string),
            style: TextStyle(
              color: brightnessTheme.text,
              fontSize: 14,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(kDefaultTextInputLimit),
            ],
            autofocus: true,
            scrollPadding: EdgeInsets.zero,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: SvgPicture.asset(
                  Resources.assetsImagesIcSearchSmallSvg,
                  colorFilter: ColorFilter.mode(
                    brightnessTheme.secondaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minHeight: 16,
                minWidth: 16,
              ),
              isDense: true,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            contextMenuBuilder: (context, state) =>
                MixinAdaptiveSelectionToolbar(editableTextState: state),
          ),
          if (isTextEmpty)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 7),
                child: Text(
                  l10n.search,
                  style: TextStyle(
                    color: brightnessTheme.secondaryText,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarSmallCloseIcon extends ConsumerWidget {
  const _AvatarSmallCloseIcon({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final iconBackground = ref.watch(
      dynamicColorProvider((
        color: darkBrightnessThemeData.divider,
        darkColor: const Color.fromRGBO(142, 141, 143, 1),
      )),
    );
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: brightnessTheme.popUp,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  Resources.assetsImagesSmallCloseSvg,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.9),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.builder,
    required this.title,
    required this.count,
    required this.hoveringColor,
  });

  final IndexedWidgetBuilder builder;
  final String title;
  final int count;
  final Color hoveringColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final headerColor = ref.watch(
      dynamicColorProvider((
        color: const Color.fromRGBO(255, 255, 255, 1),
        darkColor: const Color.fromRGBO(62, 65, 72, 1),
      )),
    );
    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        SliverPinnedHeader(
          child: Container(
            color: headerColor,
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: brightnessTheme.text,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(builder, childCount: count),
        ),
      ],
    );
  }
}

class _BaseItem extends ConsumerWidget {
  const _BaseItem({
    required this.keyword,
    required this.title,
    required this.avatar,
    required this.verified,
    required this.isBot,
    required this.membership,
    this.showSelector = false,
    this.selected = false,
  });

  final String title;
  final Widget avatar;
  final String? keyword;
  final bool showSelector;
  final bool selected;

  final bool verified;
  final bool isBot;
  final sdk.Membership? membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    return Container(
      height: 70,
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 14, right: 10),
      child: Row(
        children: [
          if (showSelector)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ClipOval(
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: selected
                        ? brightnessTheme.accent
                        : brightnessTheme.secondaryText,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(Resources.assetsImagesSelectedSvg),
                ),
              ),
            ),
          avatar,
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: CustomText(
                    title.overflow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textMatchers: [
                      EmojiTextMatcher(),
                      if (keyword != null && keyword!.trim().isNotEmpty)
                        MultiKeyWordTextMatcher.createKeywordMatcher(
                          keyword: keyword!.overflow,
                          style: TextStyle(color: brightnessTheme.accent),
                          caseSensitive: false,
                        ),
                    ],
                    style: TextStyle(
                      fontSize: 16,
                      color: brightnessTheme.text,
                    ),
                  ),
                ),
                BadgesWidget(
                  verified: verified,
                  isBot: isBot,
                  membership: membership,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
