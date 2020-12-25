import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/select_item.dart';

class SlidePage extends StatefulWidget {
  @override
  _SlidePageState createState() => _SlidePageState();
}

class _SlidePageState extends State<SlidePage> {
  int _group = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF2C3136).withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(
            height: 48,
          ),
          Text(
            'People',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          SelectItem(
            asset: 'assets/images/contacts.png',
            title: 'Contacts',
            onTap: () => {_select(-1)},
            selected: -1 == _group,
          ),
          SelectItem(
            asset: 'assets/images/group.png',
            title: 'Group',
            onTap: () => {_select(-2)},
            selected: -2 == _group,
          ),
          SelectItem(
            asset: 'assets/images/bot.png',
            title: 'Bots',
            onTap: () => {_select(-3)},
            selected: -3 == _group,
          ),
          SelectItem(
            asset: 'assets/images/strangers.png',
            title: 'Strangers',
            onTap: () => {_select(-4)},
            selected: -4 == _group,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Circle',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: [
                SelectItem(
                  asset: 'assets/images/circle.png',
                  title: 'Mixin',
                  onTap: () => {_select(0)},
                  selected: -0 == _group,
                ),
              ],
            ),
          ),
          const SelectItem(asset: 'assets/images/avatar.png', title: 'Mixin'),
        ]),
      ),
    );
  }

  bool isSelected(int index) {
    return _group == index;
  }

  void _select(int i) {
    setState(() {
      _group = i;
    });
  }
}
