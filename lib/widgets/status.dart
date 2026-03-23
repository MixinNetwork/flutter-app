import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/resources.dart';
import '../ui/provider/account_server_provider.dart';
import '../ui/provider/ui_context_providers.dart';
import '../utils/hook.dart';
import 'message/message.dart';

class StatusPending extends HookConsumerWidget {
  const StatusPending({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageId = useMessageConverter(
      converter: (state) => state.messageId,
    );
    final attachmentUtil = ref.watch(
      accountServerProvider.select(
        (value) => value.requireValue.attachmentUtil,
      ),
    );

    final value = useListenableConverter(
      attachmentUtil,
      converter: (attachmentUtil) =>
          attachmentUtil.getAttachmentProgress(messageId),
      keys: [messageId],
    ).requireData;

    return _StatusPending(value: value);
  }
}

class _StatusPending extends ConsumerWidget {
  const _StatusPending({required this.value});

  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox.fromSize(
              size: const Size.square(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.accent,
                ),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: const Duration(milliseconds: 100),
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              valueColor: AlwaysStoppedAnimation(theme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusWarning extends ConsumerWidget {
  const StatusWarning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Center(
        child: SvgPicture.asset(
          Resources.assetsImagesWarningSvg,
          colorFilter: ColorFilter.mode(
            theme.text,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class StatusDownload extends ConsumerWidget {
  const StatusDownload({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Center(
        child: SvgPicture.asset(
          Resources.assetsImagesDownloadSvg,
          colorFilter: ColorFilter.mode(
            theme.accent,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class StatusUpload extends ConsumerWidget {
  const StatusUpload({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Center(
        child: SvgPicture.asset(
          Resources.assetsImagesUploadSvg,
          colorFilter: ColorFilter.mode(
            theme.accent,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class StatusAudioPlay extends ConsumerWidget {
  const StatusAudioPlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Center(
        child: SvgPicture.asset(
          Resources.assetsImagesAudioPlaySvg,
          colorFilter: ColorFilter.mode(
            theme.accent,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class StatusAudioStop extends ConsumerWidget {
  const StatusAudioStop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _StatusLayout(
      child: Center(
        child: SvgPicture.asset(
          Resources.assetsImagesAudioStopSvg,
          colorFilter: ColorFilter.mode(
            theme.accent,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _StatusLayout extends ConsumerWidget {
  const _StatusLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: theme.statusBackground,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
