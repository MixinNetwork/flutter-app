import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';

import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/route.dart';
import 'package:flutter_app/ui/setting/bloc/setting_selected_cubit.dart';
import 'package:flutter_app/ui/setting/setting_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/widgets/automatic_keep_alive_client_widget.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/empty.dart';
import 'package:flutter_app/widgets/responsive_navigator.dart';
import 'package:flutter_app/widgets/size_policy_row.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

const slidePageMinWidth = 98.0;
const slidePageMaxWidth = 200.0;
const responsiveNavigationMinWidth = 460.0;

final _conversationPageKey = GlobalKey();

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(255, 255, 255, 1),
          darkColor: const Color.fromRGBO(44, 49, 54, 1),
        ),
        body: SizePolicyRow(
          children: [
            SizePolicyData(
              child: SlidePage(),
              minWidth: slidePageMinWidth,
              maxWidth: slidePageMaxWidth,
              sizePolicyOrder: 0,
            ),
            SizePolicyData(
              minWidth: responsiveNavigationMinWidth,
              child: ResponsiveNavigator(
                key: MixinRouter.instance.chatResponsiveNavigation,
                switchWidth: responsiveNavigationMinWidth + 260,
                leftPage: MaterialPage(
                  key: const Key('center'),
                  name: 'center',
                  child: SizedBox(
                    key: _conversationPageKey,
                    width: 300,
                    child: const _CenterPage(),
                  ),
                ),
                rightEmptyPage: MaterialPage(
                  key: const Key('empty'),
                  name: 'empty',
                  child: BlocConverter<SlideCategoryCubit, SlideCategoryState,
                      String>(
                    converter: (state) => state.name,
                    buildWhen: (a, b) => b != null,
                    builder: (context, name) => DecoratedBox(
                      child: Empty(text: 'Select a $name to start messaging'),
                      decoration: BoxDecoration(
                        color: BrightnessData.dynamicColor(
                          context,
                          const Color.fromRGBO(237, 238, 238, 1),
                          darkColor: const Color.fromRGBO(35, 39, 43, 1),
                        ),
                      ),
                    ),
                  ),
                ),
                pushPage: MixinRouter.instance.route,
              ),
            ),
          ],
        ),
      );
}

class _CenterPage extends StatelessWidget {
  const _CenterPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocListener<SlideCategoryCubit, SlideCategoryState>(
        listenWhen: (a, b) =>
            (a.type == SlideCategoryType.setting) !=
            (b.type == SlideCategoryType.setting),
        listener: (context, state) {
          final isSetting = state.type == SlideCategoryType.setting;

          MixinRouter.instance.popWhere((page) {
            try {
              return (page.key as dynamic)
                  .value
                  ?.toString()
                  ?.startsWith(MixinRouter.settingPrefix);
            } catch (e) {
              return false;
            }
          });

          if (isSetting && !MixinRouter.instance.navigationMode) {
            MixinRouter.instance.pushPage(SettingSelectedCubit.titlePageMap[
                BlocProvider.of<SettingSelectedCubit>(context).state]);
          }
        },
        child: BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
          converter: (state) => state.type == SlideCategoryType.setting,
          builder: (context, isSetting) => IndexedStack(
            index: isSetting ? 1 : 0,
            children: const [
              Positioned.fill(
                  child: AutomaticKeepAliveClientWidget(
                      child: ConversationPage())),
              Positioned.fill(
                  child: AutomaticKeepAliveClientWidget(child: SettingPage())),
            ],
          ),
        ),
      );
}
