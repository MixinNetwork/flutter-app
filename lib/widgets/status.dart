import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'message/message.dart';

class StatusPending extends HookWidget {
  const StatusPending({super.key});

  @override
  Widget build(BuildContext context) {
    final messageId =
        useMessageConverter(converter: (state) => state.messageId);

    final value = useListenableConverter(
      context.accountServer.attachmentUtil,
      converter: (AttachmentUtil attachmentUtil) =>
          attachmentUtil.getAttachmentProgress(messageId),
      keys: [messageId],
    ).requireData;

    return _StatusPending(value: value);
  }
}

class _StatusPending extends StatelessWidget {
  const _StatusPending({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox.fromSize(
                size: const Size.square(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.accent,
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value),
              duration: const Duration(milliseconds: 100),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                valueColor: AlwaysStoppedAnimation(
                  context.theme.accent,
                ),
              ),
            ),
          ],
        ),
      );
}

class StatusWarning extends StatelessWidget {
  const StatusWarning({super.key});

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesWarningSvg,
            color: context.theme.text,
          ),
        ),
      );
}

class StatusDownload extends StatelessWidget {
  const StatusDownload({super.key});

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesDownloadSvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class StatusUpload extends StatelessWidget {
  const StatusUpload({super.key});

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesUploadSvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class StatusAudioPlay extends StatelessWidget {
  const StatusAudioPlay({super.key});

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesAudioPlaySvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class StatusAudioStop extends StatelessWidget {
  const StatusAudioStop({super.key});

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesAudioStopSvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: context.theme.statusBackground,
          shape: BoxShape.circle,
        ),
        child: child,
      );
}
