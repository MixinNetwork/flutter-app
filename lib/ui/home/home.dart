import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';

class HomePage extends StatelessWidget {
  static const slidePageWidth = 200.0;
  static const conversationPageMinWidth = 260.0;
  static const conversationPageDefaultWidth = 300.0;
  static const chatPageMinWidth = 480.0;
  static const chatPageDefaultWidth = 780.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var stretchWidth = 0.0;

          var chatPageWidth =
              constraints.maxWidth - slidePageWidth - conversationPageMinWidth;
          if (chatPageWidth > chatPageDefaultWidth) {
            stretchWidth = min(chatPageWidth - chatPageDefaultWidth,
                conversationPageDefaultWidth - conversationPageMinWidth);
            chatPageWidth -= stretchWidth;
          }
          return Row(
            children: [
              SlidePage(),
              SizedBox(
                width: conversationPageMinWidth + stretchWidth,
                child: const ConversationPage(),
              ),
              SizedBox(
                width: chatPageWidth,
                child: ChatPage(),
              ),
            ],
          );
        },
      ),
    );
  }
}
