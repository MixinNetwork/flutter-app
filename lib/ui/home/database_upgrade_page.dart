import 'package:flutter/material.dart';

import '../../utils/extension/extension.dart';
import '../landing/landing.dart';

class DatabaseUpgradePage extends StatelessWidget {
  const DatabaseUpgradePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Material(
        color: context.theme.background,
        child: Center(
          child: Loading(
            title: context.l10n.databaseUpgrading,
            message: context.l10n.databaseUpgradeTips,
          ),
        ),
      );
}
