import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexagon/hexagon.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../../../constants/resources.dart';
import '../../../../../db/vo/inscription.dart';
import '../../../../../utils/extension/extension.dart';
import '../../../../interactive_decorated_box.dart';
import '../../../../mixin_image.dart';
import '../../../../toast.dart';
import '../../../message.dart';
import '../../../message_bubble.dart';
import '../../../message_datetime_and_status.dart';
import 'colored_hash_widget.dart';
import 'inscription_content.dart';
import 'inscription_dialog.dart';

class InscriptionMessage extends HookWidget {
  const InscriptionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final content = useMessageConverter(converter: (m) => m.content);
    final inscription = useMemoized(() {
      if (content == null) {
        return null;
      }
      try {
        return Inscription.fromJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      } catch (error) {
        e('InscriptionMessage: errored to parse content: $content', error);
        try {
          hex.decode(content);
          context.accountServer.addSyncInscriptionMessageJob(
            context.message.messageId,
          );
        } catch (_) {}
        return null;
      }
    }, [content]);

    return MessageBubble(
      forceIsCurrentUserColor: false,
      padding: EdgeInsets.zero,
      clip: true,
      includeNip: true,
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(
        hideStatus: true,
      ),
      child: InteractiveDecoratedBox(
        onTap: () {
          if (inscription == null) {
            showToastFailed(context.l10n.dataLoading);
            return;
          }
          showInscriptionDialog(context, inscription.inscriptionHash);
        },
        child: _InscriptionLayout(inscription: inscription),
      ),
    );
  }
}

class _InscriptionLayout extends StatelessWidget {
  const _InscriptionLayout({required this.inscription});

  final Inscription? inscription;

  @override
  Widget build(BuildContext context) {
    final defaultCollectionImage = SvgPicture.asset(
      Resources.assetsImagesCollectionPlaceholderSvg,
    );
    return SizedBox(
      width: 260,
      height: 112,
      child: Row(
        children: [
          InscriptionContent(
            inscription: inscription,
            mode: InscriptionContentMode.small,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inscription?.name ?? '',
                    style: TextStyle(color: context.theme.text, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inscription == null ? '' : '#${inscription!.sequence}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ColoredHashWidget(
                        inscriptionHex: inscription?.inscriptionHash,
                      ),
                      const SizedBox(width: 10),
                      HexagonWidget(
                        type: HexagonType.FLAT,
                        cornerRadius: 4,
                        height: 22,
                        width: 22,
                        child: SizedBox.square(
                          dimension: 22,
                          child: MixinImage.network(
                            inscription?.iconUrl ?? '',
                            errorBuilder: (_, _, _) => defaultCollectionImage,
                            placeholder: () => defaultCollectionImage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum InscriptionContentMode {
  small(2, 14),
  large(5, 24)
  ;

  final int maxLines;
  final double fontSize;
  // ignore: sort_constructors_first
  const InscriptionContentMode(this.maxLines, this.fontSize);
}

const String cacheInscriptionTextFolderName = 'cache_inscription_text';
