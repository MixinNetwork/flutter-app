import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/ui/setting/setting_page.dart';
import 'package:flutter_app/widgets/automatic_keep_alive_client_widget.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/empty.dart';
import 'package:flutter_app/widgets/size_policy_row.dart';
import 'package:provider/provider.dart';

const slidePageMinWidth = 98.0;
const slidePageMaxWidth = 200.0;
const responsiveNavigationMinWidth = 460.0;

final _conversationPageKey = GlobalKey();

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BrightnessData.themeOf(context).primary,
        body: SizePolicyRow(
          children: [
            SizePolicyData(
              child: const SlidePage(),
              minWidth: slidePageMinWidth,
              maxWidth: slidePageMaxWidth,
              sizePolicyOrder: 0,
            ),
            SizePolicyData(
              minWidth: responsiveNavigationMinWidth,
              child: ResponsiveNavigator(
                switchWidth: responsiveNavigationMinWidth + 260,
                leftPage: MaterialPage(
                  key: const ValueKey('center'),
                  name: 'center',
                  child: SizedBox(
                    key: _conversationPageKey,
                    width: 300,
                    child: const _CenterPage(),
                  ),
                ),
                rightEmptyPage: MaterialPage(
                  key: const ValueKey('empty'),
                  name: 'empty',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrightnessData.themeOf(context).chatBackground,
                    ),
                    child: Empty(
                        text: Localization.of(context).pageRightEmptyMessage),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CenterPage extends StatelessWidget {
  const _CenterPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
        converter: (state) => state.type == SlideCategoryType.setting,
        listener: (context, isSetting) {
          final responsiveNavigatorCubit =
              context.read<ResponsiveNavigatorCubit>();

          responsiveNavigatorCubit.popWhere((page) {
            if (responsiveNavigatorCubit.state.navigationMode) return true;

            return ResponsiveNavigatorCubit.settingPageNameSet
                .contains(page.name);
          });

          if (isSetting && !responsiveNavigatorCubit.state.navigationMode)
            responsiveNavigatorCubit
                .pushPage(ResponsiveNavigatorCubit.settingPageNameSet.first);
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
