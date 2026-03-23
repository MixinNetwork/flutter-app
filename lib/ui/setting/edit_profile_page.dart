import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/toast.dart';
import '../provider/account_server_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/ui_context_providers.dart';

class EditProfilePage extends HookConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final (fullName, biography, identityNumber, phone, createdAt) = ref.watch(
      authAccountProvider.select(
        (value) => (
          value?.fullName,
          value?.biography,
          value?.identityNumber,
          value?.phone,
          value?.createdAt,
        ),
      ),
    );

    final nameTextEditingController = useTextEditingController(text: fullName);
    final bioTextEditingController = useTextEditingController(text: biography);

    useEffect(() {
      accountServer.refreshSelf();
      return null;
    }, []);

    ref.listen(authAccountProvider, (previous, next) {
      if (next == null) return;
      nameTextEditingController.text = next.fullName ?? '';
      bioTextEditingController.text = next.biography;
    });

    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(
        title: Text(l10n.editProfile),
        actions: [
          MixinButton(
            onTap: () {
              runFutureWithToast(
                accountServer.updateAccount(
                  fullName: nameTextEditingController.text.trim(),
                  biography: bioTextEditingController.text.trim(),
                ),
              );
            },
            backgroundTransparent: true,
            child: Center(child: Text(l10n.save)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Builder(
              builder: (context) {
                final account = ref.watch(authAccountProvider)!;
                return AvatarWidget(
                  userId: account.userId,
                  name: account.fullName,
                  avatarUrl: account.avatarUrl,
                  size: 100,
                );
              },
            ),
            const SizedBox(height: 10),
            SelectableText(
              'Mixin ID: $identityNumber',
              style: TextStyle(
                fontSize: 14,
                color: ref.watch(
                  dynamicColorProvider((
                    color: const Color.fromRGBO(188, 190, 195, 1),
                    darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                  )),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _Item(
              title: l10n.name,
              controller: nameTextEditingController,
              maxLength: 40,
            ),
            const SizedBox(height: 32),
            _Item(
              title: l10n.biography,
              controller: bioTextEditingController,
              maxLength: 140,
            ),
            const SizedBox(height: 32),
            _Item(
              title: l10n.phoneNumber,
              controller: TextEditingController(text: phone),
              readOnly: true,
            ),
            const SizedBox(height: 70),
            Text(
              createdAt != null
                  ? l10n.joinedIn(
                      DateFormat.yMMMd().format(createdAt.toLocal()),
                    )
                  : '',
              style: TextStyle(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item({
    required this.title,
    required this.controller,
    this.readOnly = false,
    this.maxLength,
  });

  final String title;
  final TextEditingController controller;
  final bool readOnly;
  final int? maxLength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.all(Radius.circular(8)),
      gapPadding: 0,
    );

    final theme = ref.watch(brightnessThemeDataProvider);
    final backgroundColor = readOnly
        ? ref.watch(
            dynamicColorProvider((
              color: const Color.fromRGBO(236, 238, 242, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.04),
            )),
          )
        : ref.watch(
            dynamicColorProvider((
              color: const Color.fromRGBO(255, 255, 255, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
            )),
          );

    return _DynamicHorizontalPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: readOnly,
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color: readOnly ? theme.secondaryText : theme.text,
            ),
            minLines: 1,
            maxLines: 10,
            maxLength: maxLength,
            decoration: InputDecoration(
              isDense: true,
              border: outlineInputBorder,
              focusedBorder: outlineInputBorder,
              enabledBorder: outlineInputBorder,
              filled: true,
              fillColor: backgroundColor,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              counterStyle: TextStyle(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            contextMenuBuilder: (context, state) =>
                MixinAdaptiveSelectionToolbar(editableTextState: state),
          ),
        ],
      ),
    );
  }
}

class _DynamicHorizontalPadding extends StatelessWidget {
  const _DynamicHorizontalPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const maxPadding = 90.0;
      const minPadding = 20.0;
      final padding = math.min(
        maxPadding,
        math.max(minPadding, (constraints.maxWidth - 500) / 2),
      );
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: child,
      );
    },
  );
}
