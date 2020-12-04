import 'package:flutter/material.dart';

class ConversationPage extends StatelessWidget {
  final bool isSmallScreen;

  const ConversationPage({Key key, this.isSmallScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = double.infinity;
    if (!isSmallScreen) {
      width = 300;
    }
    return Container(color: Colors.green, width: width);
  }
}
