import 'package:flutter/material.dart';
import '../../widgets/avatar_view.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF23272B),
      child: Column(
        children: [
          Container(
            height: 64,
            color: Color(0xFF2C3136),
            padding: EdgeInsets.only(left: 16, right: 16),
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
                icon: Image.asset("assets/images/ic_screen.png"),
                onPressed: () {},
              ),
            ]),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Container(
            height: 64,
            color: Color(0xFF2C3136),
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset("assets/images/ic_file.png"),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Image.asset("assets/images/ic_sticker.png"),
                  onPressed: () {},
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: InputDecoration(
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Image.asset("assets/images/ic_send.png"),
                  onPressed: () {},
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
