import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/platform.dart';
import '../../../../utils/system/clipboard.dart';
import '../../../action_button.dart';
import '../../../avatar_view/avatar_view.dart';
import '../../../image.dart';
import '../../../interactive_decorated_box.dart';
import '../../../menu.dart';
import '../../../user_selector/conversation_selector.dart';
import '../../message.dart';
import '../transcript_message.dart';
import 'preview_image_widget.dart';

class ImagePreviewPage extends HookConsumerWidget {
  const ImagePreviewPage({
    super.key,
    required this.conversationId,
    required this.messageId,
    required this.isTranscriptPage,
  });

  final String conversationId;
  final String messageId;
  final bool isTranscriptPage;

  static Future<void> push(
    BuildContext context, {
    required String conversationId,
    required String messageId,
    bool isTranscriptPage = false,
  }) =>
      showGeneralDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (BuildContext buildContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          final child = ImagePreviewPage(
            conversationId: conversationId,
            messageId: messageId,
            isTranscriptPage: isTranscriptPage,
          );

          try {
            return Provider.value(
              value: context.read<TranscriptMessagesWatcher>(),
              child: child,
            );
          } catch (_) {}

          return child;
        },
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _messageId = useState(messageId);
    final current = useState<MessageItem?>(null);
    final prev = useState<MessageItem?>(null);
    final next = useState<MessageItem?>(null);

    final controller = useMemoized(
      TransformImageController.new,
      [current.value?.messageId],
    );

    final transcriptMessagesWatcher = useMemoized(() {
      try {
        return context.read<TranscriptMessagesWatcher>();
      } catch (_) {
        return null;
      }
    });

    useEffect(() {
      if (transcriptMessagesWatcher != null) return;

      if (prev.value?.messageId == _messageId.value) {
        current.value = prev.value;
      } else if (next.value?.messageId == _messageId.value) {
        current.value = next.value;
      } else {
        context.database.messageDao
            .messageItemByMessageId(_messageId.value)
            .getSingleOrNull()
            .then((value) => current.value = value);
      }
    }, [_messageId.value]);

    useEffect(() {
      if (transcriptMessagesWatcher != null) return;

      final messageDao = context.database.messageDao;
      () async {
        final info = await messageDao.messageOrderInfo(_messageId.value);
        if (info == null) return;

        await Future.wait([
          messageDao
              .mediaMessagesBefore(info, conversationId, 1)
              .getSingleOrNull()
              .then((value) => prev.value = value),
          messageDao
              .mediaMessagesAfter(info, conversationId, 1)
              .getSingleOrNull()
              .then((value) => next.value = value)
        ]);
      }();
    }, [_messageId.value]);

    useEffect(() {
      if (transcriptMessagesWatcher == null) return () {};

      final listen = transcriptMessagesWatcher
          .watchMessages()
          .map((event) =>
              event.where((element) => element.type.isImage).toList())
          .listen((messages) {
        final index = messages
            .indexWhere((element) => element.messageId == _messageId.value);

        current.value = messages.getOrNull(index);
        prev.value = messages.getOrNull(index - 1);
        next.value = messages.getOrNull(index + 1);
      });
      return listen.cancel;
    }, [_messageId.value]);

    useEffect(
      () => context.database.messageDao
          .watchInsertOrReplaceMessageStream(conversationId)
          .switchMap<MessageItem>((value) async* {
            for (final item in value) {
              yield item;
            }
          })
          .where((event) => [
                MessageCategory.plainImage,
                MessageCategory.signalImage,
              ].contains(event.type))
          .listen((event) {
            if (event.messageId == current.value?.messageId) {
              current.value = event;
            }
            if (event.messageId == prev.value?.messageId) prev.value = event;
            if (next.value?.messageId == _messageId.value) next.value = event;
          })
          .cancel,
      [conversationId],
    );

    return FocusableActionDetector(
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.keyC,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _CopyIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _PreviousImageIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _NextImageIntent(),
        const SingleActivator(LogicalKeyboardKey.zoomIn):
            const _ImageZoomInIntent(),
        SingleActivator(
          LogicalKeyboardKey.equal,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _ImageZoomInIntent(),
        SingleActivator(
          LogicalKeyboardKey.minus,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _ImageZoomOutIntent(),
        const SingleActivator(LogicalKeyboardKey.zoomOut):
            const _ImageZoomOutIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyR,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _ImageRotateIntent(),
      },
      actions: {
        _CopyIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => copyFile(context.accountServer
              .convertMessageAbsolutePath(current.value, isTranscriptPage)),
        ),
        _PreviousImageIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            if (prev.value == null) {
              return false;
            }
            _messageId.value = prev.value!.messageId;
            return true;
          },
        ),
        _NextImageIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            if (next.value == null) {
              return false;
            }
            _messageId.value = next.value!.messageId;
            return true;
          },
        ),
        _ImageZoomInIntent: CallbackAction<Intent>(
          onInvoke: (intent) => controller.zoomIn(),
        ),
        _ImageZoomOutIntent: CallbackAction<Intent>(
          onInvoke: (intent) => controller.zoomOut(),
        ),
        _ImageRotateIntent: CallbackAction<Intent>(
          onInvoke: (intent) => controller.rotate(),
        ),
      },
      autofocus: true,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: context.theme.primary,
                ),
                child: Builder(
                  builder: (context) {
                    if (current.value == null) return const SizedBox();
                    return Row(
                      children: [
                        const SizedBox(width: 100),
                        Expanded(
                          child: _Bar(
                            message: current.value!,
                            controller: controller,
                            isTranscriptPage: isTranscriptPage,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (current.value == null) return const SizedBox();
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => _Item(
                            message: current.value!,
                            controller: controller,
                            isTranscriptPage: isTranscriptPage,
                            constraints: constraints,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              children: [
                                if (prev.value != null)
                                  InteractiveDecoratedBox(
                                    onTap: () => _messageId.value =
                                        prev.value!.messageId,
                                    child: SvgPicture.asset(
                                      Resources.assetsImagesNextSvg,
                                    ),
                                  ),
                                const Spacer(),
                                if (next.value != null)
                                  InteractiveDecoratedBox(
                                    onTap: () => _messageId.value =
                                        next.value!.messageId,
                                    child: SvgPicture.asset(
                                      Resources.assetsImagesPrevSvg,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.message,
    required this.controller,
    required this.isTranscriptPage,
  });

  final MessageItem message;
  final TransformImageController controller;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AvatarWidget(
            name: message.userFullName,
            size: 36,
            avatarUrl: message.avatarUrl,
            userId: message.userId,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.userFullName!,
                style: TextStyle(
                  fontSize: MessageItemWidget.primaryFontSize,
                  color: context.theme.text,
                ),
              ),
              Text(
                message.userIdentityNumber,
                style: TextStyle(
                  fontSize: MessageItemWidget.secondaryFontSize,
                  color: context.theme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          _Action(
            controller: controller,
            isTranscriptPage: isTranscriptPage,
            message: message,
          ),
          const SizedBox(width: 24),
        ],
      );
}

enum _ActionType { share, copy, download }

class _Action extends StatelessWidget {
  const _Action({
    required this.controller,
    required this.isTranscriptPage,
    required this.message,
  });

  final TransformImageController controller;
  final bool isTranscriptPage;
  final MessageItem message;

  static const _dividerWidth = 14.0;
  static const _divider = SizedBox(width: _dividerWidth);
  static const _width = 36;

  @override
  Widget build(BuildContext context) {
    Future<void> share() async {
      final accountServer = context.accountServer;
      final result = await showConversationSelector(
        context: context,
        singleSelect: true,
        title: context.l10n.forward,
        onlyContact: false,
      );
      if (result == null || result.isEmpty) return;
      await accountServer.forwardMessage(
        message.messageId,
        result.first.encryptCategory!,
        conversationId: result.first.conversationId,
        recipientId: result.first.userId,
      );
    }

    Future<void> copy() => copyFile(context.accountServer
        .convertMessageAbsolutePath(message, isTranscriptPage));

    Future<void> download() async {
      if (message.mediaUrl?.isEmpty ?? true) return;
      await saveAs(context, context.accountServer, message, isTranscriptPage);
    }

    final collapsible = [
      if (!isTranscriptPage)
        ActionButton(
          name: Resources.assetsImagesShareSvg,
          size: 20,
          color: context.theme.icon,
          onTap: share,
        ),
      ActionButton(
        name: Resources.assetsImagesCopySvg,
        color: context.theme.icon,
        size: 20,
        onTap: copy,
      ),
      ActionButton(
        name: Resources.assetsImagesAttachmentDownloadSvg,
        color: context.theme.icon,
        size: 20,
        onTap: download,
      )
    ];

    final close = ActionButton(
      name: Resources.assetsImagesIcCloseBigSvg,
      color: context.theme.icon,
      size: 20,
      onTap: () => Navigator.pop(context),
    );

    final common = [
      ActionButton(
        name: Resources.assetsImagesZoomInSvg,
        color: context.theme.icon,
        size: 20,
        onTap: controller.zoomIn,
      ),
      ActionButton(
        name: Resources.assetsImagesZoomOutSvg,
        size: 20,
        color: context.theme.icon,
        onTap: controller.zoomOut,
      ),
      ActionButton(
        name: Resources.assetsImagesRotatoSvg,
        color: context.theme.icon,
        size: 20,
        onTap: controller.rotate,
      ),
    ];

    final menu = PopupMenuPageButton(
      itemBuilder: (context) => [
        CustomPopupMenuButton(
          icon: Resources.assetsImagesShareSvg,
          title: context.l10n.forward,
          value: _ActionType.share,
        ),
        CustomPopupMenuButton(
          icon: Resources.assetsImagesCopySvg,
          title: context.l10n.copy,
          value: _ActionType.copy,
        ),
        CustomPopupMenuButton(
          icon: Resources.assetsImagesAttachmentDownloadSvg,
          title: context.l10n.download,
          value: _ActionType.download,
        ),
      ],
      onSelected: (type) {
        switch (type) {
          case _ActionType.share:
            share();
            break;
          case _ActionType.copy:
            copy();
            break;
          case _ActionType.download:
            download();
            break;
        }
      },
      icon: SvgPicture.asset(
        Resources.assetsImagesEllipsisSvg,
        height: 24,
        width: 24,
        colorFilter: ColorFilter.mode(
          context.theme.icon,
          BlendMode.srcIn,
        ),
      ),
    );

    return Expanded(
      child: LayoutBuilder(builder: (context, constraints) {
        final count = common.length + collapsible.length + 1;
        final collapsed = (count * _width + (count - 1) * _dividerWidth) >=
            constraints.maxWidth;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ...common,
            if (!collapsed) ...collapsible,
            close,
            if (collapsed) menu,
          ].joinList(_divider),
        );
      }),
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item({
    required this.message,
    required this.controller,
    required this.isTranscriptPage,
    required this.constraints,
  });

  final MessageItem message;
  final bool isTranscriptPage;
  final TransformImageController controller;

  // constraints of layout.
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // scale image to fit viewport on first show.
    final initialScale = useMemoized(() {
      final imageSize = Size(
        (message.mediaWidth ?? 0).toDouble(),
        (message.mediaHeight ?? 0).toDouble(),
      );
      if (imageSize.isEmpty) {
        assert(false, 'image message size is empty: ${message.messageId}');
        return 1.0;
      }
      final layoutSize = constraints.biggest;

      final scale = math.min(layoutSize.width / imageSize.width,
          layoutSize.height / imageSize.height);
      return math.min<double>(scale, 1);
    }, [message.messageId]);

    return GestureDetector(
      onDoubleTap: () {
        controller.animatedToScale(initialScale);
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(62, 65, 72, 0.9),
        ),
        child: ClipRect(
          child: ImagPreviewWidget(
            scale: initialScale,
            minScale: math.min(initialScale / 2, 0.5),
            maxScale: math.max(initialScale * 2, 2),
            controller: controller,
            onEmptyAreaTapped: () {
              Navigator.maybePop(context);
            },
            image: Image.file(
              File(context.accountServer
                  .convertMessageAbsolutePath(message, isTranscriptPage)),
              fit: BoxFit.contain,
              errorBuilder: (context, error, s) => ImageByBlurHashOrBase64(
                imageData: message.thumbImage ?? '',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _PreviousImageIntent extends Intent {
  const _PreviousImageIntent();
}

class _NextImageIntent extends Intent {
  const _NextImageIntent();
}

class _ImageZoomInIntent extends Intent {
  const _ImageZoomInIntent();
}

class _ImageZoomOutIntent extends Intent {
  const _ImageZoomOutIntent();
}

class _ImageRotateIntent extends Intent {
  const _ImageRotateIntent();
}
