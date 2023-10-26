import 'package:flutter/material.dart';

import '../../utils/extension/extension.dart';
import 'landing.dart';

class AppInitializingPage extends StatelessWidget {
  const AppInitializingPage({super.key});

  @override
  Widget build(BuildContext context) => LandingScaffold(
        child: Center(
          child: LoadingWidget(
            title: context.l10n.initializing,
            message: context.l10n.chatHintE2e,
          ),
        ),
      );
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.text;
    return SizedBox(
      width: 375,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.dynamicColor(
                const Color.fromRGBO(188, 190, 195, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
