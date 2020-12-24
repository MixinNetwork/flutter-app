import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/input_container.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool expaned = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          flex: 1,
          child: ChatContainer(
            isSelected: expaned,
            onPressed: () {
              setState(() {
                expaned = !expaned;
              });
            },
          )),
      AnimatedContainer(
        width: expaned ? 300 : 0,
        decoration: const BoxDecoration(color: Color(0xFF2C3136)),
        duration: const Duration(milliseconds: 120),
      )
    ]);
  }
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    Key key,
    this.onPressed,
    this.isSelected,
  }) : super(key: key);

  final Function onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF23272B),
      child: Column(
        children: [
          ChatBar(onPressed: onPressed, isSelected: isSelected),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          const InputContainer()
        ],
      ),
    );
  }
}
