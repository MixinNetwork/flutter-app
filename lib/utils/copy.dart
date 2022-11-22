import 'package:pasteboard/pasteboard.dart';

import '../widgets/toast.dart';

Future<void> copyFile(String? filePath) async {
  if (filePath?.isEmpty ?? true) {
    return showToastFailed(null);
  }
  try {
    await Pasteboard.writeFiles([filePath!]);
  } catch (error) {
    showToastFailed(error);
    return;
  }
  showToastSuccessful();
}
