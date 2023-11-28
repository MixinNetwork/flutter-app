import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../widgets/dialog.dart';
import 'landing.dart';

// https://sqlite.org/rescode.html
const _kSqliteCorrupt = 11;
const _kSqliteLocked = 6;
const _kSqliteNotADb = 26;
const _kSqliteBusy = 5;

typedef DeleteDatabaseCallback = Future<void> Function();
typedef OpenDatabaseCallback = Future<void> Function();
typedef CloseDatabaseCallback = Future<void> Function();

class DatabaseOpenFailedPage extends StatelessWidget {
  const DatabaseOpenFailedPage({
    required this.error,
    required this.openDatabaseCallback,
    required this.deleteDatabaseCallback,
    required this.closeDatabaseCallback,
    super.key,
  });

  final SqliteException error;
  final OpenDatabaseCallback openDatabaseCallback;
  final DeleteDatabaseCallback deleteDatabaseCallback;
  final CloseDatabaseCallback closeDatabaseCallback;

  @override
  Widget build(BuildContext context) {
    final String message;
    switch (error.resultCode) {
      case _kSqliteCorrupt:
        message = context.l10n.databaseCorruptedTips;
      case _kSqliteLocked:
        message = context.l10n.databaseLockedTips;
      case _kSqliteNotADb:
        message = context.l10n.databaseNotADbTips;
      default:
        message = '${error.explanation}';
    }
    final canDeleteDatabase =
        const {_kSqliteCorrupt, _kSqliteNotADb}.contains(error.resultCode);

    final canRetry = error.resultCode == _kSqliteBusy;

    return LandingFailedPage(
      title: context.l10n.failedToOpenDatabase,
      message: message,
      actions: [
        if (canDeleteDatabase)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RecreateDatabaseButton(
              openDatabaseCallback: openDatabaseCallback,
              deleteDatabaseCallback: deleteDatabaseCallback,
              closeDatabaseCallback: closeDatabaseCallback,
            ),
          ),
        if (canRetry)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _Button(
              onTap: () async {
                await closeDatabaseCallback();
                await openDatabaseCallback();
              },
              text: context.l10n.retry,
            ),
          ),
        _Button(
          onTap: () {
            exit(1);
          },
          text: context.l10n.exit,
        )
      ],
    );
  }
}

class _RecreateDatabaseButton extends HookConsumerWidget {
  const _RecreateDatabaseButton({
    required this.openDatabaseCallback,
    required this.deleteDatabaseCallback,
    required this.closeDatabaseCallback,
  });

  final OpenDatabaseCallback openDatabaseCallback;
  final DeleteDatabaseCallback deleteDatabaseCallback;
  final CloseDatabaseCallback closeDatabaseCallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
        onPressed: () async {
          final result = await showConfirmMixinDialog(
            context,
            context.l10n.databaseRecreateTips,
            positiveText: context.l10n.create,
          );
          if (result != DialogEvent.positive) {
            return;
          }
          await closeDatabaseCallback();
          await deleteDatabaseCallback();
          await openDatabaseCallback();
        },
        child: Text(
          context.l10n.continueText,
          style: TextStyle(
            color: context.theme.red,
          ),
        ),
      );
}

Future<void> dropDatabaseFile(String dbDir, String dbName) async {
  // Rename the old database file to a new name with timestamp.
  final now = DateTime.now();
  renameFileWithTime(p.join(dbDir, '$dbName.db'), now);
  await Future.forEach(
    [
      File(p.join(dbDir, '$dbName.db-shm')),
      File(p.join(dbDir, '$dbName.db-wal'))
    ].where((e) => e.existsSync()),
    (element) => renameFileWithTime(element.path, now),
  );
}

class _Button extends StatelessWidget {
  const _Button({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.accent,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(text),
      );
}

class LandingFailedPage extends StatelessWidget {
  const LandingFailedPage({
    required this.message,
    required this.actions,
    required this.title,
    super.key,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LandingScaffold(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                message,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            ...actions,
            const SizedBox(height: 32),
          ],
        ),
      );
}

/// Failed to open app with an unknown error.
class OpenAppFailedPage extends StatelessWidget {
  const OpenAppFailedPage({
    required this.error,
    super.key,
  });

  final dynamic error;

  @override
  Widget build(BuildContext context) => LandingFailedPage(
          title: context.l10n.unknowError,
          message: error.toString(),
          actions: [
            ElevatedButton(
              onPressed: () {
                exit(1);
              },
              child: Text(context.l10n.exit),
            )
          ]);
}
