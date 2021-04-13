import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/search_cubit.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/Toast.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/menu.dart';
import 'package:flutter_app/widgets/user_selector/conversation_selector.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'action_button.dart';
import 'avatar_view/avatar_view.dart';
import 'dialog.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
      ),
      borderRadius: BorderRadius.all(
        Radius.circular(20.0),
      ),
      gapPadding: 0,
    );
    final backgroundColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final hintColor = BrightnessData.themeOf(context).secondaryText;
    return ColoredBox(
      color: BrightnessData.themeOf(context).primary,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TextField(
                focusNode: context.read<FocusNode>(),
                controller: context.read<TextEditingController>(),
                onChanged: (keyword) =>
                    context.read<SearchCubit>().keyword = keyword,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).text,
                  fontSize: 14,
                ),
                scrollPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  isDense: true,
                  border: outlineInputBorder,
                  focusedBorder: outlineInputBorder,
                  enabledBorder: outlineInputBorder,
                  filled: true,
                  fillColor: backgroundColor,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  prefixIconConstraints:
                      const BoxConstraints.expand(width: 40, height: 32),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: SvgPicture.asset(
                      Resources.assetsImagesIcSearchSvg,
                      color: hintColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(right: 8),
                  hintText: Localization.of(context).search,
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ContextMenuPortalEntry(
            buildMenus: () => [
              ContextMenu(
                title: Localization.of(context).createConversation,
                onTap: () async {
                  final list = await showConversationSelector(
                    context: context,
                    singleSelect: true,
                    title: Localization.of(context).createCircle,
                    onlyContact: true,
                  );
                  if (list.isEmpty) return;
                  final id = list[0].item1;
                },
              ),
              ContextMenu(
                title: Localization.of(context).createGroupConversation,
                onTap: () async {
                  final result = await showConversationSelector(
                    context: context,
                    singleSelect: false,
                    title: Localization.of(context).createGroupConversation,
                    onlyContact: true,
                  );
                  if (result.isEmpty) return;
                  final userIds = [
                    context.read<AccountServer>().userId,
                    ...result.map(
                      (e) => e.item1,
                    )
                  ];

                  final name = await showMixinDialog<String>(
                    context: context,
                    child: _NewConversationConfirm(userIds),
                  );
                  if (name?.isEmpty ?? true) return;

                  showToastLoading(context);
                  try {
                    await context
                        .read<AccountServer>()
                        .createGroupConversation(name!, userIds);
                  } catch (e) {
                    return showToastFailed(context);
                  }
                  showToastSuccessful(context);
                },
              ),
              ContextMenu(
                title: Localization.of(context).createCircle,
                onTap: () async {
                  final list = await showConversationSelector(
                    context: context,
                    singleSelect: false,
                    title: Localization.of(context).createCircle,
                    onlyContact: false,
                  );

                  if (list.isEmpty) return;

                  final name = await showMixinDialog<String>(
                    context: context,
                    child: const EditCircleNameDialog(),
                  );

                  if (name?.isEmpty ?? true) return;

                  showToastLoading(context);

                  try {
                    await context
                        .read<AccountServer>()
                        .createCircle(name!, list.map((e) => e.item1).toList());
                  } catch (e) {
                    return showToastFailed(context);
                  }
                  showToastSuccessful(context);
                },
              ),
            ],
            child: Builder(
                builder: (context) => ActionButton(
                      name: Resources.assetsImagesIcAddSvg,
                      size: 16,
                      onTapUp: (event) {
                        context.read<OffsetCubit>().emit(event.globalPosition);
                      },
                      onTap: () async {
                        return;
                      },
                      padding: const EdgeInsets.all(8),
                      color: BrightnessData.themeOf(context).icon,
                    )),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _NewConversationConfirm extends HookWidget {
  const _NewConversationConfirm(
    this.userIds, {
    Key? key,
  }) : super(key: key);

  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final users = useMemoizedFuture(
      () => context
          .read<AccountServer>()
          .database
          .userDao
          .usersByIn(userIds.sublist(0, min(4, userIds.length)))
          .get(),
      <User>[],
    );

    final textEditingController = useTextEditingController();
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: Text(Localization.of(context).group),
      titleMarginBottom: 24,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              height: 60,
              width: 60,
              child: AvatarPuzzlesWidget(users, 60),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Localization.of(context).participantsCount(userIds.length),
            style: TextStyle(
              fontSize: 14,
              color: BrightnessData.themeOf(context).secondaryText,
            ),
          ),
          const SizedBox(height: 48),
          DialogTextField(
            textEditingController: textEditingController,
            hintText: '',
          ),
        ],
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            child: Text(Localization.of(context).cancel),
            onTap: () => Navigator.pop(context)),
        MixinButton(
          child: Text(Localization.of(context).create),
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
        ),
      ],
    );
  }
}
