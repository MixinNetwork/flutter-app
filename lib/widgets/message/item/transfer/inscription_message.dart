import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexagon/hexagon.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../../constants/resources.dart';
import '../../../../db/vo/inscription.dart';
import '../../../../utils/extension/extension.dart';
import '../../../cache_image.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';

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
            jsonDecode(content) as Map<String, dynamic>);
      } catch (error) {
        e('InscriptionMessage: errored to parse content: $content', error);
        try {
          hex.decode(content);
          context.accountServer
              .addSyncInscriptionMessageJob(context.message.messageId);
        } catch (_) {}
        return null;
      }
    }, [content]);
    return MessageBubble(
      forceIsCurrentUserColor: false,
      padding: EdgeInsets.zero,
      clip: true,
      includeNip: true,
      outerTimeAndStatusWidget:
          const MessageDatetimeAndStatus(hideStatus: true),
      child: InteractiveDecoratedBox(
        onTap: () {},
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
    final defaultInscriptionImage =
        SvgPicture.asset(Resources.assetsImagesInscriptionPlaceholderSvg);
    final defaultCollectionImage =
        SvgPicture.asset(Resources.assetsImagesCollectionPlaceholderSvg);
    return SizedBox(
      width: 260,
      height: 112,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 112,
            child: inscription == null
                ? defaultInscriptionImage
                : CacheImage(
                    inscription?.contentUrl ?? '',
                    errorWidget: () => defaultInscriptionImage,
                    placeholder: () => defaultInscriptionImage,
                  ),
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
                      _ColoredHashWidget(
                        inscriptionHex: inscription?.inscriptionHash,
                      ),
                      const SizedBox(width: 10),
                      HexagonWidget(
                        type: HexagonType.FLAT,
                        cornerRadius: 2,
                        height: 20,
                        width: 22,
                        child: SizedBox.square(
                          dimension: 22,
                          child: inscription == null
                              ? defaultCollectionImage
                              : CacheImage(
                                  inscription!.iconUrl ?? '',
                                  errorWidget: () => defaultCollectionImage,
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

class _ColoredHashWidget extends HookWidget {
  const _ColoredHashWidget({required this.inscriptionHex});

  final String? inscriptionHex;

  @override
  Widget build(BuildContext context) {
    final colors = useMemoized(() {
      if (inscriptionHex == null) {
        return List.filled(12, Colors.black12);
      }
      final bytes = inscriptionHex!.hexToBytes();
      final data = bytes + sha3Hash(bytes).sublist(0, 4);
      final colors = <Color>[];
      for (var i = 0; i < data.length; i += 3) {
        colors.add(Color.fromARGB(0xFF, data[i], data[i + 1], data[i + 2]));
      }
      return colors;
    }, [inscriptionHex]);
    return Row(
      children: <Widget>[
        for (final color in colors)
          Container(
            width: 5,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ].joinList(const SizedBox(width: 3)),
    );
  }
}
