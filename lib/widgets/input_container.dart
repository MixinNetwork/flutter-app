import 'package:flutter/material.dart';

import 'action_button.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF2C3136),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              ActionButton(
                name: "assets/images/ic_file.png",
                onTap: () {},
              ),
              ActionButton(
                name: "assets/images/ic_sticker.png",
                onTap: () {},
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
              ActionButton(name: "assets/images/ic_send.png", onTap: () {})
            ],
          ),
        ),
      ),
    );
  }
}
