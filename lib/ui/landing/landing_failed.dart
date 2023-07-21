import 'package:flutter/material.dart';

import 'landing.dart';

class LandingFailedPage extends StatelessWidget {
  const LandingFailedPage({
    super.key,
    required this.message,
    required this.actions,
    required this.title,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LandingScaffold(
        child: Column(
          children: [
            Expanded(child: Center(child: Text(message))),
            ...actions,
            const SizedBox(height: 32),
          ],
        ),
      );
}
