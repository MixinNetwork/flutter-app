import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../bloc/simple_cubit.dart';
import '../../constants/brightness_theme_data.dart';
import '../../constants/resources.dart';
import '../../crypto/uuid/uuid.dart';
import '../../db/mixin_database.dart';
import '../../enum/encrypt_category.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../action_button.dart';
import '../avatar_view/avatar_view.dart';
import '../dialog.dart';
import '../high_light_text.dart';
import '../interactive_decorated_box.dart';
import 'bloc/conversation_filter_cubit.dart';

String _getConversationName(dynamic item) {
  if (item is ConversationItem) return item.validName;
  if (item is User) return item.fullName ?? '?';
  throw ArgumentError('must be ConversationItem or User');
}

String _getConversationId(dynamic item, BuildContext context) {
  if (item is ConversationItem) return item.conversationId;
  if (item is User) {
    return generateConversationId(
      item.userId,
      context.accountServer.userId,
    );
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
  Widget get avatarWidget => ConversationAvatarWidget(
        size: 50,
        conversation: this,
      );
}

Future<List<ConversationSelector>?> showConversationSelector({
  required BuildContext context,
  required bool singleSelect,
  required String title,
  required bool onlyContact,
  bool allowEmpty = false,
  List<ConversationSelector> initSelected = const [],
  String? confirmedText,
  Widget? action,
}) =>
    showMixinDialog<List<ConversationSelector>?>(
      context: context,
      child: _ConversationSelector(
        title: title,
        singleSelect: singleSelect,
        onlyContact: onlyContact,
        initSelected: initSelected,
        allowEmpty: allowEmpty,
        confirmedText: confirmedText,
        action: action,
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
  List<Object?> get props => [
        conversationId,
        userId,
        encryptCategory,
      ];

  static ConversationSelector init(
          dynamic item, BuildContext context, Map<String, App> map) =>
      ConversationSelector(
        conversationId: _getConversationId(item, context),
        userId: _getUserId(item),
        encryptCategory: _getEncryptedCategory(item, map),
      );
}

class _ConversationSelector extends HookWidget {
  const _ConversationSelector({
    required this.singleSelect,
    required this.title,
    required this.onlyContact,
    this.initSelected = const [],
    this.allowEmpty = false,
    this.confirmedText,
    this.action,
  });

  final String title;
  final bool singleSelect;
  final bool onlyContact;
  final List<ConversationSelector> initSelected;
  final bool allowEmpty;
  final String? confirmedText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final selector = useBloc(() => SimpleCubit<List<dynamic>>(const []));
    void selectItem(dynamic item) {
      final list = [...selector.state];
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
      selector.emit(list);
    }

    final conversationFilterCubit = useBloc(() => ConversationFilterCubit(
            useContext().accountServer, onlyContact, (state) {
          state.recentConversations.forEach((element) {
            if (!initSelected
                .map((e) => e.conversationId)
                .contains(element.conversationId)) return;
            selectItem(element);
          });

          final userIds = initSelected.map((e) => e.userId);
          state.friends.forEach((element) {
            if (!userIds.contains(element.userId)) return;
            selectItem(element);
          });
          state.bots.forEach((element) {
            if (!userIds.contains(element.userId)) return;
            selectItem(element);
          });
        }));
    final conversationFilterState =
        useBlocState<ConversationFilterCubit, ConversationFilterState>(
      bloc: conversationFilterCubit,
    );

    final appMap = useMemoizedFuture(
      () async {
        final list = await context.database.appDao
            .appInIds(conversationFilterState.appIds)
            .get();
        return {for (var e in list) e.appId: e};
      },
      <String, App>{},
      keys: [conversationFilterState],
    ).requireData;

    useEffect(
      () => selector.stream.listen((event) {
        if (event.isNotEmpty && singleSelect) {
          final item = event.first;
          Navigator.pop(
              context, [ConversationSelector.init(item, context, appMap)]);
        }
      }).cancel,
      [selector.stream],
    );
    final selected =
        useBlocState<SimpleCubit<List<dynamic>>, List<dynamic>>(bloc: selector);

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
                        color: context.theme.icon,
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
                              color: context.theme.text,
                              fontSize: 16,
                            ),
                          ),
                          if (!singleSelect)
                            Text(
                              '${selected.length} / ${conversationFilterState.recentConversations.length + conversationFilterState.friends.length + conversationFilterState.bots.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.theme.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: action ??
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
                                            context,
                                            appMap,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  child: Text(
                                    confirmedText ?? context.l10n.next,
                                  ),
                                )
                              : const SizedBox()),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(top: 8, right: 24, left: 24),
              decoration: BoxDecoration(
                color: context.theme.background,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: TextField(
                onChanged: (string) => conversationFilterCubit.keyword = string,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 14,
                ),
                autofocus: true,
                scrollPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: SvgPicture.asset(
                      Resources.assetsImagesIcSearchSmallSvg,
                      colorFilter: ColorFilter.mode(
                        context.theme.secondaryText,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minHeight: 16,
                    minWidth: 16,
                  ),
                  isDense: true,
                  hintText: context.l10n.search,
                  hintStyle: TextStyle(color: context.theme.secondaryText),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
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
                                    onTap: () => selectItem(selected[index]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getConversationName(selected[index]),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.theme.text,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        separatorBuilder: (BuildContext context, int index) =>
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
                        title: context.l10n.recentChats,
                        count:
                            conversationFilterState.recentConversations.length,
                        builder: (BuildContext context, int index) {
                          final item = conversationFilterState
                              .recentConversations[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: context.theme.listSelected,
                            onTap: () => selectItem(item),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.validName,
                              selected: selected.any((element) =>
                                  _getConversationId(element, context) ==
                                  _getConversationId(item, context)),
                              showSelector: !singleSelect,
                            ),
                          );
                        },
                      ),
                    if (conversationFilterState.friends.isNotEmpty)
                      _Section(
                        title: context.l10n.contactTitle,
                        count: conversationFilterState.friends.length,
                        builder: (BuildContext context, int index) {
                          final item = conversationFilterState.friends[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: context.theme.listSelected,
                            onTap: () => selectItem(item),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.fullName ?? '',
                              showSelector: !singleSelect,
                              selected: selected.any((element) =>
                                  _getConversationId(element, context) ==
                                  _getConversationId(item, context)),
                            ),
                          );
                        },
                      ),
                    if (conversationFilterState.bots.isNotEmpty)
                      _Section(
                        title: context.l10n.bots,
                        count: conversationFilterState.bots.length,
                        builder: (BuildContext context, int index) {
                          final item = conversationFilterState.bots[index];
                          return InteractiveDecoratedBox.color(
                            decoration: boxDecoration,
                            hoveringColor: context.theme.listSelected,
                            onTap: () => selectItem(item),
                            child: _BaseItem(
                              keyword: conversationFilterState.keyword,
                              avatar: item.avatarWidget,
                              title: item.fullName!,
                              showSelector: !singleSelect,
                              selected: selected.any((element) =>
                                  _getConversationId(element, context) ==
                                  _getConversationId(item, context)),
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

class _AvatarSmallCloseIcon extends StatelessWidget {
  const _AvatarSmallCloseIcon({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
        top: 0,
        right: 0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.theme.popUp,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  color: context.dynamicColor(
                    darkBrightnessThemeData.divider,
                    darkColor: const Color.fromRGBO(142, 141, 143, 1),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    Resources.assetsImagesSmallCloseSvg,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.9),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.builder,
    required this.title,
    required this.count,
  });

  final IndexedWidgetBuilder builder;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => MultiSliver(
        pushPinnedChildren: true,
        children: [
          SliverPinnedHeader(
            child: Container(
              color: context.dynamicColor(
                const Color.fromRGBO(255, 255, 255, 1),
                darkColor: const Color.fromRGBO(62, 65, 72, 1),
              ),
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: context.theme.text,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              builder,
              childCount: count,
            ),
          ),
        ],
      );
}

class _BaseItem extends StatelessWidget {
  const _BaseItem({
    required this.keyword,
    required this.title,
    required this.avatar,
    this.showSelector = false,
    this.selected = false,
  });

  final String title;
  final Widget avatar;
  final String? keyword;
  final bool showSelector;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        height: 70,
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 14, right: 10),
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
                          ? context.theme.accent
                          : context.theme.secondaryText,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(Resources.assetsImagesSelectedSvg),
                  ),
                ),
              ),
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: HighlightText(
                title.overflow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                highlightTextSpans: [
                  if (keyword != null)
                    HighlightTextSpan(
                      keyword!.overflow,
                      style: TextStyle(color: context.theme.accent),
                    )
                ],
                style: TextStyle(
                  fontSize: 16,
                  color: context.theme.text,
                ),
              ),
            ),
          ],
        ),
      );
}
