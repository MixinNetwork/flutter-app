import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../account/account_key_value.dart';
import '../constants/constants.dart';
import '../widgets/dialog.dart';
import 'extension/extension.dart';
import 'logger.dart';
import 'system/package_info.dart';

final github = GitHub();

Future<void> checkUpdate({
  required BuildContext context,
  bool force = false,
}) async {
  final lastCheckUpdate = AccountKeyValue.instance.checkUpdateLastTime;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (!force && now - lastCheckUpdate < hours24) {
    d('checkUpdate: skip');
    return;
  }
  try {
    final release = await github.repositories.getLatestRelease(
      RepositorySlug('MixinNetwork', 'flutter-app'),
    );
    final packageInfo = await getPackageInfo();
    final currentVersion = 'v${packageInfo.version}';

    i('Latest release: ${release.tagName} ${release.publishedAt}, current version: $currentVersion');

    AccountKeyValue.instance.checkUpdateLastTime = now;

    if (!force && release.tagName == AccountKeyValue.instance.ignoredVersion) {
      // ignore this version
      return;
    }
    if (currentVersionIsLatest(currentVersion, release.tagName!)) {
      // current version is the latest
      return;
    }
    await showMixinDialog(
      context: context,
      child: _UpdateDialog(
        release: release,
        ignored: release.tagName == AccountKeyValue.instance.ignoredVersion,
        currentVersion: currentVersion,
      ),
    );
  } catch (error, stackTrace) {
    e('check update failed: $error, $stackTrace');
  }
}

@visibleForTesting
bool currentVersionIsLatest(String currentVersion, String tagName) {
  assert(currentVersion.isNotEmpty);
  assert(tagName.isNotEmpty);
  assert(currentVersion.startsWith('v'));
  assert(tagName.startsWith('v'));

  final currentVersionNumber = currentVersion.substring(1);
  final tagNameNumber = tagName.substring(1);

  final currentVersionParts =
      currentVersionNumber.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final tagNameParts =
      tagNameNumber.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  for (var i = 0; i < currentVersionParts.length; i++) {
    if (tagNameParts.length <= i) {
      return false;
    }
    if (currentVersionParts[i] > tagNameParts[i]) {
      return true;
    }
    if (currentVersionParts[i] < tagNameParts[i]) {
      return false;
    }
  }
  return true;
}

class _UpdateDialog extends HookWidget {
  const _UpdateDialog({
    Key? key,
    required this.release,
    required this.ignored,
    required this.currentVersion,
  }) : super(key: key);

  final Release release;

  final bool ignored;

  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final ignoreUpdate = useState(ignored);
    return SizedBox(
      width: 400,
      child: AlertDialogLayout(
        title: Text(context.l10n.newVersionAvailable),
        titleMarginBottom: 24,
        content: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: context.theme.text,
          ),
          child: Column(
            children: [
              Text(context.l10n.newVersionDescription(
                  release.tagName ?? '', currentVersion)),
              if (!ignored)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: ignoreUpdate.value,
                        onChanged: (checked) {
                          final ignore = checked ?? false;
                          ignoreUpdate.value = ignore;
                          AccountKeyValue.instance.ignoredVersion =
                              ignore ? release.tagName : null;
                        },
                      ),
                      Text(
                        context.l10n.ignoreThisUpdate,
                        style: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          MixinButton(
            onTap: () => launchUrlString('https://mixin.one/messenger'),
            child: Text(context.l10n.download),
          ),
        ],
      ),
    );
  }
}
