import 'package:flutter/material.dart';

import './responsive_layout.dart';
import './chat_page.dart';
import './slide_page.dart';
import './conversation_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: ResponsiveLayout(
          largeScreen: Row(
            children: [
              SlidePage(),
              ConversationPage(isSmallScreen: false),
              Expanded(
                flex: 1,
                child: ChatPage(),
              ),
            ],
          ),
          mediumScreen: Row(children: [
            ConversationPage(isSmallScreen: false),
            Expanded(flex: 1, child: ChatPage()),
          ]),
          smallScreen: Container(
              child: ConversationPage(
            isSmallScreen: true,
          )),
        ));
  }
}
