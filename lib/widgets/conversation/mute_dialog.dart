import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tuple/tuple.dart';

import '../../utils/extension/extension.dart';
import '../dialog.dart';
import '../radio.dart';

class MuteDialog extends HookWidget {
  const MuteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final result = useState<int?>(null);
    return AlertDialogLayout(
      title: Text(context.l10n.muteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tuple2(context.l10n.mute1hour, 1 * 60 * 60),
            Tuple2(context.l10n.mute8hours, 8 * 60 * 60),
            Tuple2(context.l10n.mute1week, 7 * 24 * 60 * 60),
            Tuple2(context.l10n.mute1year, 365 * 24 * 60 * 60),
          ]
              .map(
                (e) => RadioItem<int>(
                  title: Text(e.item1),
                  groupValue: result.value,
                  value: e.item2,
                  onChanged: (int? value) => result.value = value,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        MixinButton(
          onTap: () => Navigator.pop(context, result.value),
          child: Text(context.l10n.confirm),
        ),
      ],
    );
  }
}
