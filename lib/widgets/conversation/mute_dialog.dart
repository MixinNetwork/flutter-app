import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tuple/tuple.dart';

import '../../utils/extension/extension.dart';
import '../dialog.dart';
import '../radio.dart';

class MuteDialog extends HookWidget {
  const MuteDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = useState<int?>(null);
    return AlertDialogLayout(
      title: Text(context.l10n.contactMuteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tuple2(context.l10n.oneHour, 1 * 60 * 60),
            Tuple2(context.l10n.hour(8), 8 * 60 * 60),
            Tuple2(context.l10n.oneWeek, 7 * 24 * 60 * 60),
            Tuple2(context.l10n.oneYear, 365 * 24 * 60 * 60),
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
