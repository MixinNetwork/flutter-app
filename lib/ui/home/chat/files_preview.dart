import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../widgets/dialog.dart';

void showFilesPreviewDialog(BuildContext context, List<XFile> files) {
  showMixinDialog(
    context: context,
    child: _FilesPreviewDialog(
      initialFiles: files,
    ),
  );
}

class _FilesPreviewDialog extends StatelessWidget {
  const _FilesPreviewDialog({Key? key, required this.initialFiles})
      : super(key: key);

  final List<XFile> initialFiles;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
