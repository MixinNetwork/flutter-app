import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/bloc_converter.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/automatic_keep_alive_client_widget.dart';
import '../../widgets/empty.dart';
import '../setting/setting_page.dart';
import 'bloc/conversation_cubit.dart';
import 'bloc/multi_auth_cubit.dart';
import 'bloc/slide_category_cubit.dart';
import 'conversation_page.dart';
import 'route/responsive_navigator.dart';
import 'route/responsive_navigator_cubit.dart';
import 'slide_page.dart';

// chat category list min width
const kSlidePageMinWidth = 64.0;
// chat category and chat list max width
const kSlidePageMaxWidth = 200.0;
// chat page min width, message list, setting page etc.
const kResponsiveNavigationMinWidth = 300.0;
// conversation list fixed width, conversation list, setting list etc.
const kConversationListWidth = 300.0;
// chat side page fixed width, chat info page etc.
const kChatSidePageWidth = 300.0;

final _conversationPageKey = GlobalKey();

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            _HomePage(
          constraints: constraints,
        ),
      );
}

class CollapseValueNotifier extends ValueNotifier<bool> {
  CollapseValueNotifier(bool value) : super(value);
}

class _HomePage extends HookWidget {
  const _HomePage({
    Key? key,
    required this.constraints,
  }) : super(key: key);

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final maxWidth = constraints.maxWidth;
    final clampSlideWidth = (maxWidth - kResponsiveNavigationMinWidth)
        .clamp(kSlidePageMinWidth, kSlidePageMaxWidth);

    final userCollapse =
        useBlocStateConverter<MultiAuthCubit, MultiAuthState, bool>(
      converter: (state) => state.collapsedSidebar,
    );

    final autoCollapse = clampSlideWidth < kSlidePageMaxWidth;
    final collapse = userCollapse || autoCollapse;

    return Scaffold(
      backgroundColor: context.theme.primary,
      body: SafeArea(
        child: Row(
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(
                end: collapse ? kSlidePageMinWidth : kSlidePageMaxWidth,
              ),
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, double? value, Widget? child) =>
                  SizedBox(
                width: value,
                child: child,
              ),
              child: SlidePage(showCollapse: !autoCollapse),
            ),
            Expanded(
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
                      color: context.theme.chatBackground,
                    ),
                    child: Empty(text: context.l10n.pageRightEmptyMessage),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPage extends StatelessWidget {
  const _CenterPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.primary,
          border: Border(
            right: BorderSide(
              color: context.theme.divider,
            ),
          ),
        ),
        child: BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
          converter: (state) => state.type == SlideCategoryType.setting,
          listener: (context, isSetting) {
            final responsiveNavigatorCubit =
                context.read<ResponsiveNavigatorCubit>();

            responsiveNavigatorCubit.popWhere((page) {
              if (responsiveNavigatorCubit.state.routeMode) return true;

              return ResponsiveNavigatorCubit.settingPageNameSet
                  .contains(page.name);
            });

            if (isSetting && !responsiveNavigatorCubit.state.routeMode) {
              context.read<ConversationCubit>().unselected();
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
                    child: ConversationPage(),
                  ),
                ),
                Positioned.fill(
                    child:
                        AutomaticKeepAliveClientWidget(child: SettingPage())),
              ],
            ),
          ),
        ),
      );
}
