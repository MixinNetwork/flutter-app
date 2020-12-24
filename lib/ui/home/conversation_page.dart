import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/search_bar.dart';

import '../../utils/avatar_mock.dart';
import '../../widgets/avatar_view.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({Key key, this.isSmallScreen}) : super(key: key);

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    var width = double.infinity;
    if (!isSmallScreen) {
      width = 300;
    }
    return Container(
      width: width,
      color: const Color(0xFF2C3136),
      child: Column(
        children: [
          const SearchBar(),
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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          AvatarView(
            size: 50,
            avatars: moackAvatar(index),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text('Name', style: TextStyle(color: Colors.white, fontSize: 18)),
              Text('37303051',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}
