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
    return Container(
      width: width,
      color: Color(0xFF2C3136),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.only(left: 12, right: 12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(26)),
            child: TextField(
              onChanged: (string) => {},
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.08),
                ),
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.08)),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
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
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey,
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
