import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexagon/hexagon.dart';

import '../../../../../constants/resources.dart';
import '../../../../../db/vo/inscription.dart';
import '../../../../../utils/cache_client.dart';
import '../../../../../utils/extension/extension.dart';
import '../../../../../utils/hook.dart';
import '../../../../mixin_image.dart';
import 'inscription_message.dart';

class InscriptionContent extends HookWidget {
  const InscriptionContent({
    required this.inscription,
    required this.mode,
    super.key,
  });

  final Inscription? inscription;
  final InscriptionContentMode mode;

  @override
  Widget build(BuildContext context) {
    final defaultInscriptionImage = SvgPicture.asset(
      Resources.assetsImagesInscriptionPlaceholderSvg,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: switch (inscription) {
        Inscription(contentType: final type, contentUrl: final contentUrl)
            when type.startsWith('image') =>
          MixinImage.network(
            contentUrl,
            errorBuilder: (_, _, _) => defaultInscriptionImage,
            placeholder: () => defaultInscriptionImage,
          ),
        Inscription(
          contentType: final type,
          contentUrl: final contentUrl,
          iconUrl: final iconUrl?,
        )
            when type.startsWith('text') =>
          _TextInscriptionContent(
            contentUrl: contentUrl,
            iconUrl: iconUrl,
            mode: mode,
          ),
        _ => defaultInscriptionImage,
      },
    );
  }
}

// Replace all invisible characters with a placeholder ■
@visibleForTesting
String inscriptionDisplayContent(String content) => content.replaceAll(
  RegExp(r'[\s\p{Other}\p{Cf}\p{Cc}\p{Cn}]', unicode: true),
  '■',
);

class _TextInscriptionContent extends HookWidget {
  const _TextInscriptionContent({
    required this.contentUrl,
    required this.iconUrl,
    required this.mode,
  });

  final String contentUrl;
  final String iconUrl;
  final InscriptionContentMode mode;

  @override
  Widget build(BuildContext context) {
    final defaultCollectionImage = SvgPicture.asset(
      Resources.assetsImagesCollectionPlaceholderSvg,
    );

    final client = useMemoized(
      () => CacheClient(
        context.database.settingProperties.activatedProxy,
        cacheInscriptionTextFolderName,
      ),
      [],
    );

    final text =
        useMemoizedFuture(
          () async {
            final response = await client.get(Uri.parse(contentUrl));
            final text = utf8.decode(response.bodyBytes, allowMalformed: true);
            return inscriptionDisplayContent(text);
          },
          null,
          keys: [client, contentUrl],
        ).data;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Resources.assetsImagesTextBgPng),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = TextStyle(
              color: const Color.fromRGBO(255, 167, 36, 1),
              fontSize: mode.fontSize,
              fontWeight: FontWeight.bold,
            );
            final autoSizeText = AutoSizeText(
              text ?? '',
              maxLines: mode.maxLines,
              maxFontSize: 24,
              minFontSize: 14,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              textAlign: TextAlign.center,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HexagonWidget(
                  type: HexagonType.FLAT,
                  cornerRadius: constraints.maxWidth / 3 / 5,
                  height: constraints.maxWidth / 3,
                  width: constraints.maxWidth / 3,
                  child: SizedBox.square(
                    dimension: constraints.maxWidth / 3,
                    child: MixinImage.network(
                      iconUrl,
                      errorBuilder: (_, _, _) => defaultCollectionImage,
                      placeholder: () => defaultCollectionImage,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: constraints.maxWidth / 40,
                    right: constraints.maxWidth / 10,
                    left: constraints.maxWidth / 10,
                  ),
                  child:
                      mode == InscriptionContentMode.large
                          ? autoSizeText
                          : _MinLinesWrapper(
                            text: text,
                            style: textStyle,
                            minLines: mode.maxLines,
                            child: autoSizeText,
                          ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MinLinesWrapper extends HookWidget {
  const _MinLinesWrapper({
    required this.text,
    required this.style,
    required this.child,
    this.minLines = 1,
  });

  final String? text;
  final TextStyle style;
  final Widget child;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final minHeight = useMemoized(() {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: minLines,
      )..layout(maxWidth: MediaQuery.of(context).size.width);

      return textPainter.preferredLineHeight * minLines;
    }, [text, style, minLines]);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: child,
    );
  }
}
