import 'package:flutter/material.dart';

class SlidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Color(0xFF2C3136).withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 48,
          ),
          Text(
            "People",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          SizedBox(
            height: 16,
          ),
          SelectItem(
              asset: 'assets/images/contacts.png',
              title: "Contacts",
              isSelected: true),
          SelectItem(asset: 'assets/images/group.png', title: "Group"),
          SelectItem(asset: 'assets/images/bot.png', title: "Bots"),
          SelectItem(asset: 'assets/images/strangers.png', title: "Strangers"),
          SizedBox(
            height: 16,
          ),
          Text(
            "Circle",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: [
                SelectItem(asset: 'assets/images/circle.png', title: "Mixin"),
              ],
            ),
          ),
          SelectItem(asset: 'assets/images/avatar.png', title: "Mixin"),
        ]),
      ),
    );
  }
}

class SelectItem extends StatelessWidget {
  final String asset;
  final String title;
  final isSelected;
  const SelectItem({Key key, this.title, this.isSelected = false, this.asset})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    BoxDecoration background;
    if (isSelected) {
      background = BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8));
    }
    return Container(
      decoration: background,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.asset(asset, width: 24),
            SizedBox(width: 12),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 14))
          ],
        ),
      ),
    );
  }
}
