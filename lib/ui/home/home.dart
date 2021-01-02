import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';

import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/widgets/responsive_navigator.dart';
import 'package:flutter_app/widgets/size_policy_row.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const slidePageMinWidth = 98.0;
const slidePageMaxWidth = 200.0;
const responsiveNavigationMinWidth = 460.0;

class HomePage extends StatelessWidget {
  final _conversationPageKey = GlobalKey();
  final _chatPageKey = GlobalKey();
  final _chatResponsiveNavigation = GlobalKey<ResponsiveNavigatorState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
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
              child: BlocListener<ConversationCubit, Conversation>(
                listenWhen: (a, b) => (a != null) != (b != null),
                listener: (context, state) {
                  _chatResponsiveNavigation.currentState
                      .showRightPage(state != null, false);
                },
                child: ResponsiveNavigator(
                  key: _chatResponsiveNavigation,
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
                  rightPage: MaterialPage(
                    key: const Key('chatPage'),
                    name: 'chatPage',
                    child: ChatPage(key: _chatPageKey),
                  ),
                  // TODO Other pages of the current route
                  // ignore: missing_return
                  pushPage: (String name, Object arguments) {},
                ),
              ),
            ),
          ],
        ),
      );
}
