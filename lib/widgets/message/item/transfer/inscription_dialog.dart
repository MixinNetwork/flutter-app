import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/brightness_theme_data.dart';
import '../../../../db/vo/inscription.dart';
import '../../../../ui/provider/database_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../buttons.dart';
import '../../../cache_image.dart';
import '../../../dialog.dart';
import '../../../high_light_text.dart';
import 'inscription_message.dart';

Future<void> showInscriptionDialog(
  BuildContext context,
  String inscriptionHash,
) =>
    showMixinDialog(
      context: context,
      child: _InscriptionDialog(inscriptionHash),
    );

final _inscriptionProvider = StreamProvider.family<Inscription?, String>(
    (ref, inscriptionHash) => ref
        .read(databaseProvider)
        .requireValue
        .inscriptionItemDao
        .inscriptionByHash(inscriptionHash)
        .watchSingleOrNull());

class _InscriptionDialog extends ConsumerWidget {
  const _InscriptionDialog(this.inscriptionHash);

  final String inscriptionHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inscription =
        ref.watch(_inscriptionProvider(inscriptionHash)).valueOrNull;
    const theme = darkBrightnessThemeData;
    return SizedBox(
      width: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (inscription == null)
            const Material(color: Colors.black87)
          else
            CacheImage(inscription.contentUrl),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, top: 12),
                      child: MixinCloseButton(color: theme.icon),
                    ),
                  ],
                ),
                if (inscription == null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.theme.secondaryText,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: _InscriptionDetailLayout(inscription: inscription),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InscriptionDetailLayout extends StatelessWidget {
  const _InscriptionDetailLayout({required this.inscription});

  final Inscription inscription;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CacheImage(inscription.contentUrl),
            ),
            const SizedBox(height: 20),
            _ItemInfoTile(
              title: Text(context.l10n.hash),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColoredHashWidget(
                    inscriptionHex: inscription.inscriptionHash,
                    blockSize: const ui.Size(7, 18),
                    space: 4,
                  ),
                  const SizedBox(height: 4),
                  CustomSelectableText(
                    inscription.inscriptionHash,
                    style:
                        TextStyle(color: darkBrightnessThemeData.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ItemInfoTile(
              title: Text(context.l10n.id),
              subtitle: Text('#${inscription.sequence}'),
            ),
            const SizedBox(height: 20),
            _ItemInfoTile(
              title: Text(context.l10n.collection),
              subtitle: Text(inscription.name ?? ''),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
}

class _ItemInfoTile extends StatelessWidget {
  const _ItemInfoTile({
    required this.title,
    required this.subtitle,
  });

  final Widget title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    const theme = darkBrightnessThemeData;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(
            color: theme.secondaryText,
            fontSize: 16,
          ),
          child: title,
        ),
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          style: TextStyle(
            color: theme.text,
            fontSize: 16,
          ),
          child: subtitle,
        ),
      ],
    );
  }
}
