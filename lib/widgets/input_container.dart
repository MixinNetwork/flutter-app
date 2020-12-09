import 'package:flutter/material.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
