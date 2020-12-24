import 'package:flutter/material.dart';

import 'action_button.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24)),
              child: TextField(
                onChanged: (string) => {},
                style: const TextStyle(
                  color: Colors.white,
                ),
                scrollPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  icon: Image.asset('assets/images/ic_search.png',
                      width: 20, height: 20),
                  contentPadding: const EdgeInsets.all(0),
                  isDense: true,
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.08)),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ActionButton(
                name: 'assets/images/ic_create_group.png',
                onTap: () {
                  _showDialog(context);
                }),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return const CreateGroupContanier();
        });
  }
}

class CreateGroupContanier extends StatelessWidget {
  const CreateGroupContanier({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: Material(
        color: Colors.transparent,
        child: Container(
            width: 480,
            height: 600,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3E4148),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                Row(children: [
                  ActionButton(
                      name: 'assets/images/ic_close.png',
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  const Spacer(),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(
                          text: 'Add Participants\n',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: '3/256',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.4))),
                    ]),
                    textAlign: TextAlign.center,
                    strutStyle: const StrutStyle(height: 1.5),
                  ),
                  const Spacer(),
                  const InkWell(
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  )
                ]),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    onChanged: (string) => {},
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    scrollPadding: EdgeInsets.zero,
                    decoration: InputDecoration(
                      icon: Image.asset('assets/images/ic_search.png',
                          width: 20, height: 20),
                      contentPadding: const EdgeInsets.all(0),
                      isDense: true,
                      hintText: 'Search',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.08)),
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
