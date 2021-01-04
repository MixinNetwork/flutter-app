import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';

import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/empty.dart';
import 'package:flutter_app/widgets/responsive_navigator.dart';
import 'package:flutter_app/widgets/size_policy_row.dart';

const slidePageMinWidth = 98.0;
const slidePageMaxWidth = 200.0;
const responsiveNavigationMinWidth = 460.0;

final _conversationPageKey = GlobalKey();
final _chatPageKey = GlobalKey();
final chatResponsiveNavigation = GlobalKey<ResponsiveNavigatorState>();

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) =>
      Scaffold(
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
                key: chatResponsiveNavigation,
                switchWidth: responsiveNavigationMinWidth + 260,
                leftPage: MaterialPage(
                  key: const Key('conversation'),
                  name: 'conversation',
                  child: SizedBox(
                    key: _conversationPageKey,
                    width: 300,
                    child: const ConversationPage(),
                  ),
                ),
                rightEmptyPage: MaterialPage(
                  key: const Key('empty'),
                  name: 'empty',
                  child: BlocConverter<SlideCategoryCubit,
                      SlideCategoryState,
                      String>(
                    converter: (state) => state.name,
                    builder: (context, name) =>
                        DecoratedBox(
                          child: Empty(
                              text: 'Select a $name to start messaging'),
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
                pushPage: (String name, Object arguments) {
                  if (name == 'chatPage') {
                    return MaterialPage(
                      key: const Key('chatPage'),
                      name: 'chatPage',
                      child: ChatPage(key: _chatPageKey),
                    );
                  }
                  throw ArgumentError('Invalid route');
                },
              ),
            ),
          ],
        ),
      );
}
