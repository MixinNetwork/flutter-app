import 'package:flutter/material.dart';

import 'avatar_view.dart';

class ChatBar extends StatelessWidget {
  const ChatBar({
    Key key,
    @required this.onPressed,
    this.isSelected,
  }) : super(key: key);

  final Function onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Color(0xFF2C3136),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
                flex: 1,
                child: Row(children: [
                  AvatarView(
                    size: 50,
                    avatars: [
                      "https://i1.hdslb.com/bfs/face/3e285abab2a9fd1d52fb640a03f7d458bf139045.jpg",
                    ],
                  ),
                  SizedBox(width: 16),
                  Text("Name",
                      style: TextStyle(color: Colors.white, fontSize: 20))
                ])),
            IconButton(
              icon: Image.asset("assets/images/ic_search.png"),
              onPressed: () {},
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Image.asset("assets/images/ic_screen.png",
                  color: isSelected ? Colors.blue : Colors.white),
              onPressed: onPressed,
            ),
          ]),
        ));
  }
}
