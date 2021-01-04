import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/app_bar.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
      children: [
        MixinAppBar(
          title: 'Notification',
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
}
