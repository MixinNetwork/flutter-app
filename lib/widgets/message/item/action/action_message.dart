import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../brightness_observer.dart';
import '../../../interacter_decorated_box.dart';

class ActionMessage extends StatelessWidget {
  const ActionMessage({
    Key key,
    this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          child: Builder(
            builder: (context) {
              final List<dynamic> json = jsonDecode(message.content);
              final list = json.map((e) => ActionData.fromJson(e));
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: list
                    .map(
                      (e) => InteractableDecoratedBox.color(
                        onTap: () => launch(e.action),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: BrightnessData.themeOf(context).primary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorHex(e.color) ?? Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      );
}
