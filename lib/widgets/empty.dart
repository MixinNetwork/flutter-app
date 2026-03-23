import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/provider/ui_context_providers.dart';

class Empty extends ConsumerWidget {
  const Empty({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Center(
      child: Text(
        text,
        style: TextStyle(color: theme.secondaryText),
      ),
    );
  }
}
