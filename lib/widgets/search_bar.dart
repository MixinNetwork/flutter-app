import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24)),
            child: TextField(
              onChanged: (string) => {},
              style: TextStyle(
                color: Colors.white,
              ),
              scrollPadding: EdgeInsets.zero,
              decoration: InputDecoration(
                icon: Image.asset('assets/images/ic_search.png',
                    width: 20, height: 20),
                contentPadding: EdgeInsets.all(0),
                isDense: true,
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.08)),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Image.asset('assets/images/ic_create_group.png'),
            onPressed: () {},
          ),
        )
      ],
    );
  }
}
