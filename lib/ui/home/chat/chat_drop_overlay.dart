import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/extension/extension.dart';
import '../../../widgets/dash_path_border.dart';
import 'files_preview.dart';

class ChatDropOverlay extends HookWidget {
  const ChatDropOverlay({required this.child, required this.enable, super.key});

  final Widget child;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    final dragging = useState(false);
    final dialogEnabled = useState(true);
    return DropTarget(
      onDragEntered: (_) => dragging.value = true,
      onDragExited: (_) => dragging.value = false,
      onDragDone: (details) async {
        final files = details.files.where((xFile) {
          final file = File(xFile.path);
          return file.existsSync();
        }).toList();
        if (files.isEmpty) return;

        dialogEnabled.value = false;
        await showFilesPreviewDialog(
          context,
          files.map((file) => file.withMineType()).toList(),
        );
        dialogEnabled.value = true;
      },
      enable: enable && dialogEnabled.value,
      child: Stack(
        children: [child, if (dragging.value) const _ChatDragIndicator()],
      ),
    );
  }
}

class _ChatDragIndicator extends StatelessWidget {
  const _ChatDragIndicator();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.theme.popUp),
    child: Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.listSelected,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: DashPathBorder.all(
          borderSide: BorderSide(color: context.theme.divider),
          dashArray: CircularIntervalList([4, 4]),
        ),
      ),
      child: Center(
        child: Text(
          context.l10n.dragAndDropFileHere,
          style: TextStyle(fontSize: 14, color: context.theme.text),
        ),
      ),
    ),
  );
}
