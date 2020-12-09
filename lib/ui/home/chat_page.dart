import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/input_container.dart';
import '../../widgets/avatar_view.dart';

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
                this.expaned = !this.expaned;
              });
            },
          )),
      AnimatedContainer(
        width: expaned ? 300 : 0,
        decoration: BoxDecoration(color: Color(0xFF2C3136)),
        duration: Duration(milliseconds: 120),
      )
    ]);
  }
}

class ChatContainer extends StatelessWidget {
  final Function onPressed;
  final bool isSelected;
  const ChatContainer({
    Key key,
    this.onPressed,
    this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF23272B),
      child: Column(
        children: [
          ChatBar(onPressed: onPressed, isSelected: isSelected),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          InputContainer()
        ],
      ),
    );
  }
}
