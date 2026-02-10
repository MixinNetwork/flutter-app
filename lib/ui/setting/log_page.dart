import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../widgets/action_button.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/high_light_text.dart';

Future<void> showLogPage(BuildContext context) => showGeneralDialog(
  context: context,
  barrierColor: Colors.transparent,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  pageBuilder:
      (
        buildContext,
        animation,
        secondaryAnimation,
      ) => InheritedTheme.capture(
        from: context,
        to: Navigator.of(context, rootNavigator: true).context,
      ).wrap(const _LogPage()),
);

class _LogPage extends HookWidget {
  const _LogPage();

  @override
  Widget build(BuildContext context) {
    useListenable(_logChangeNotifier);
    return Material(
      color: context.theme.background,
      child: Column(
        children: [
          MixinAppBar(
            leading: const SizedBox(),
            actions: [
              ActionButton(
                color: context.theme.icon,
                onTap: () {
                  scheduleMicrotask(() {
                    i(
                      'scheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotaskscheduleMicrotask',
                    );
                  });
                  launchUrl(Uri.file(mixinLogDirectory.path));
                },
                child: const Icon(Icons.launch),
              ),
              const SizedBox(width: 8),
              MixinCloseButton(onTap: () => Navigator.pop(context)),
            ],
          ),
          Expanded(
            child: CustomSelectableArea(
              child: ListView.builder(
                itemCount: _logs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final log = _logs[_logs.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    child: CustomText(log),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _logs = [];

final _logChangeNotifier = ValueNotifier<bool>(true);

void onWriteLogToFile(String log) {
  _logs.add(log);
  if (_logs.length > 1000) {
    _logs.removeAt(0);
  }
  scheduleMicrotask(() {
    _logChangeNotifier.value = !_logChangeNotifier.value;
  });
}
