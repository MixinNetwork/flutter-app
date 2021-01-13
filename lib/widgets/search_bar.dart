import 'package:flutter/material.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';

import 'action_button.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
      ),
      borderRadius: BorderRadius.all(
        Radius.circular(20.0),
      ),
      gapPadding: 0,
    );
    final backgroundColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final hintColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(184, 189, 199, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.3),
    );
    return Row(
      children: [
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TextField(
              onChanged: (string) => {},
              style: TextStyle(
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(51, 51, 51, 1),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
                ),
                fontSize: 14,
              ),
              scrollPadding: EdgeInsets.zero,
              decoration: InputDecoration(
                isDense: true,
                border: outlineInputBorder,
                focusedBorder: outlineInputBorder,
                enabledBorder: outlineInputBorder,
                filled: true,
                fillColor: backgroundColor,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                prefixIconConstraints:
                    const BoxConstraints.expand(width: 40, height: 32),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Image.asset(
                    Resources.assetsImagesIcSearchPng,
                    color: hintColor,
                  ),
                ),
                contentPadding: const EdgeInsets.only(right: 8),
                hintText: Localization.of(context).search,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ActionButton(
          name: Resources.assetsImagesIcCreateGroupPng,
          onTap: () {
            _showDialog(context);
          },
          padding: const EdgeInsets.all(8),
          size: 24,
          color: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(47, 48, 50, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
          ),
        ),
        const SizedBox(width: 12),
      ],
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
