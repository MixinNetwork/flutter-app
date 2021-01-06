import 'package:flutter/material.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/ui/setting/setting_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/widgets/automatic_keep_alive_client_widget.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/empty.dart';
import 'package:flutter_app/widgets/size_policy_row.dart';

import 'bloc/auth_cubit.dart';

const slidePageMinWidth = 98.0;
const slidePageMaxWidth = 200.0;
const responsiveNavigationMinWidth = 460.0;

final _conversationPageKey = GlobalKey();

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Blaze().connect(AuthCubit.of(context));
    return Scaffold(
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
                  when: (a, b) => b != null,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterPage extends StatelessWidget {
  const _CenterPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
        converter: (state) => state.type == SlideCategoryType.setting,
        listener: (context, isSetting) {
          final responsiveNavigatorCubit = ResponsiveNavigatorCubit.of(context);

          responsiveNavigatorCubit.popWhere((page) {
            if (responsiveNavigatorCubit.state.navigationMode) return true;

            return ResponsiveNavigatorCubit.settingTitlePageMap.values
                .any((element) => page.name == element);
          });

          if (isSetting && !responsiveNavigatorCubit.state.navigationMode)
            responsiveNavigatorCubit.pushPage(
                ResponsiveNavigatorCubit.settingTitlePageMap.values.first);
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
