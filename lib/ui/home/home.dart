import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/bloc_converter.dart';
import '../../generated/l10n.dart';
import '../../widgets/automatic_keep_alive_client_widget.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/empty.dart';
import '../../widgets/size_policy_row.dart';
import '../setting/setting_page.dart';
import 'bloc/slide_category_cubit.dart';
import 'conversation_page.dart';
import 'route/responsive_navigator.dart';
import 'route/responsive_navigator_cubit.dart';
import 'slide_page.dart';

// chat category list min width
const kSlidePageMinWidth = 80.0;
// chat category and chat list max width
const kSlidePageMaxWidth = 160.0;
// chat page min width, message list, setting page etc.
const kResponsiveNavigationMinWidth = 460.0;
// conversation list fixed width, conversation list, setting list etc.
const kConversationListWidth = 300.0;
// chat side page fixed width, chat info page etc.
const kChatSidePageWidth = 300.0;

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
              minWidth: kSlidePageMinWidth,
              maxWidth: kSlidePageMaxWidth,
              sizePolicyOrder: 0,
            ),
            SizePolicyData(
              minWidth: kResponsiveNavigationMinWidth,
              child: ResponsiveNavigator(
                switchWidth:
                    kResponsiveNavigationMinWidth + kConversationListWidth,
                leftPage: MaterialPage(
                  key: const ValueKey('center'),
                  name: 'center',
                  child: SizedBox(
                    key: _conversationPageKey,
                    width: kConversationListWidth,
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

          if (isSetting && !responsiveNavigatorCubit.state.navigationMode) {
            responsiveNavigatorCubit
                .pushPage(ResponsiveNavigatorCubit.settingPageNameSet.first);
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
