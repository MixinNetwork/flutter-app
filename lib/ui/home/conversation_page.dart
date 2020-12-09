import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/search_bar.dart';
import '../../widgets/avatar_view.dart';
import '../../utils/avatar_mock.dart';

class ConversationPage extends StatelessWidget {
  final bool isSmallScreen;

  ConversationPage({Key key, this.isSmallScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = double.infinity;
    if (!isSmallScreen) {
      width = 300;
    }
    return Container(
      width: width,
      color: Color(0xFF2C3136),
      child: Column(
        children: [
          SearchBar(),
          Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: 100,
                itemBuilder: _itemBuilder,
              ))
        ],
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          AvatarView(
            size: 50,
            avatars: moackAvatar(index),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Name", style: TextStyle(color: Colors.white, fontSize: 18)),
              Text("37303051",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}
