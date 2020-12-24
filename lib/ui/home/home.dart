import 'package:flutter/material.dart';

import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/widgets/responsive_layout.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: ResponsiveLayout(
          largeScreen: Row(
            children: [
              SlidePage(),
              const ConversationPage(isSmallScreen: false),
              Expanded(
                flex: 1,
                child: ChatPage(),
              ),
            ],
          ),
          mediumScreen: Row(children: [
            const ConversationPage(isSmallScreen: false),
            Expanded(flex: 1, child: ChatPage()),
          ]),
          smallScreen: const ConversationPage(
            isSmallScreen: true,
          ),
        ));
  }
}
