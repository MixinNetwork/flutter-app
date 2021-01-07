import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(246, 247, 250, 0.9),
          darkColor: const Color.fromRGBO(40, 44, 48, 1),
        ),
        appBar: MixinAppBar(
          title: Localization.of(context).notification,
          actions: [],
        ),
      );
}
