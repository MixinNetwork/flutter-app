import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/file.dart';
import '../../../../utils/platform.dart';
import '../../../action_button.dart';
import '../../../avatar_view/avatar_view.dart';
import '../../../image.dart';
import '../../../interactive_decorated_box.dart';
import '../../../toast.dart';
import '../../../user_selector/conversation_selector.dart';
import '../../message.dart';
import '../transcript_message.dart';

class ImagePreviewPage extends HookWidget {
  const ImagePreviewPage({
    Key? key,
    required this.conversationId,
    required this.messageId,
    required this.isTranscriptPage,
  }) : super(key: key);

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
  Widget build(BuildContext context) {
    final controller = useMemoized(() => PhotoViewScaleStateController());
    final _messageId = useState(messageId);
    final current = useState<MessageItem?>(null);
    final prev = useState<MessageItem?>(null);
    final next = useState<MessageItem?>(null);

    final transcriptMessagesWatcher = useMemoized(() {
      try {
        return context.read<TranscriptMessagesWatcher>();
      } catch (_) {
        return null;
      }
    });

    useEffect(() {
      controller.scaleState = PhotoViewScaleState.initial;
    }, [_messageId.value]);

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
        final rowId =
            await messageDao.messageRowId(_messageId.value).getSingleOrNull();
        if (rowId == null) return;

        prev.value = await messageDao
            .mediaMessagesBefore(rowId, conversationId, 1)
            .getSingleOrNull();
        next.value = await messageDao
            .mediaMessagesAfter(rowId, conversationId, 1)
            .getSingleOrNull();
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
      () => context.database.messageDao.insertOrReplaceMessageStream
          .switchMap<MessageItem>((value) async* {
            for (final item in value) {
              yield item;
            }
          })
          .where((event) =>
              event.conversationId == conversationId &&
              [
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
      },
      actions: {
        _CopyIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => _copyUrl(
              context,
              context.accountServer
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
      },
      autofocus: true,
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
                      _Item(
                        message: current.value!,
                        controller: controller,
                        isTranscriptPage: isTranscriptPage,
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: [
                              if (prev.value != null)
                                InteractiveDecoratedBox(
                                  onTap: () =>
                                      _messageId.value = prev.value!.messageId,
                                  child: SvgPicture.asset(
                                    Resources.assetsImagesNextSvg,
                                  ),
                                ),
                              const Spacer(),
                              if (next.value != null)
                                InteractiveDecoratedBox(
                                  onTap: () =>
                                      _messageId.value = next.value!.messageId,
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
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    Key? key,
    required this.message,
    required this.controller,
    required this.isTranscriptPage,
  }) : super(key: key);

  final MessageItem message;
  final PhotoViewScaleStateController controller;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AvatarWidget(
            name: message.userFullName!,
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
          const Spacer(),
          ActionButton(
            name: Resources.assetsImagesZoomInSvg,
            color: context.theme.icon,
            size: 20,
            onTap: () => controller.scaleState = PhotoViewScaleState.covering,
          ),
          const SizedBox(width: 14),
          ActionButton(
            name: Resources.assetsImagesZoomOutSvg,
            size: 20,
            color: context.theme.icon,
            onTap: () => controller.scaleState = PhotoViewScaleState.initial,
          ),
          const SizedBox(width: 14),
          if (!isTranscriptPage)
            ActionButton(
              name: Resources.assetsImagesShareSvg,
              size: 20,
              color: context.theme.icon,
              onTap: () async {
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
              },
            ),
          if (!isTranscriptPage) const SizedBox(width: 14),
          ActionButton(
            name: Resources.assetsImagesCopySvg,
            color: context.theme.icon,
            size: 20,
            onTap: () => _copyUrl(
                context,
                context.accountServer
                    .convertMessageAbsolutePath(message, isTranscriptPage)),
          ),
          const SizedBox(width: 14),
          ActionButton(
            name: Resources.assetsImagesAttachmentDownloadSvg,
            color: context.theme.icon,
            size: 20,
            onTap: () async {
              if (message.mediaUrl?.isEmpty ?? true) return;
              await saveFileToSystem(
                context,
                context.accountServer
                    .convertMessageAbsolutePath(message, isTranscriptPage),
                suggestName: message.mediaName,
              ).then((succeed) {
                if (succeed) {
                  showToastSuccessful(context);
                }
              }).onError((error, stackTrace) {
                showToastFailed(context, error);
              });
            },
          ),
          const SizedBox(width: 14),
          ActionButton(
            name: Resources.assetsImagesIcCloseBigSvg,
            color: context.theme.icon,
            size: 20,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 24),
        ],
      );
}

class _Item extends HookWidget {
  const _Item({
    Key? key,
    required this.message,
    required this.controller,
    required this.isTranscriptPage,
  }) : super(key: key);
  final MessageItem message;
  final PhotoViewScaleStateController controller;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context) {
    final zoomIn = useStream(controller.outputScaleStateStream,
                initialData: PhotoViewScaleState.initial)
            .data ==
        PhotoViewScaleState.initial;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(62, 65, 72, 0.9),
        ),
        child: Center(
          child: ClipRect(
            child: MouseRegion(
              cursor: zoomIn
                  ? SystemMouseCursors.zoomIn
                  : SystemMouseCursors.zoomOut,
              child: PhotoView(
                tightMode: true,
                imageProvider: FileImage(File(context.accountServer
                    .convertMessageAbsolutePath(message, isTranscriptPage))),
                maxScale: PhotoViewComputedScale.contained * 2.0,
                minScale: PhotoViewComputedScale.contained * 0.8,
                initialScale: PhotoViewComputedScale.contained,
                scaleStateController: controller,
                onTapUp: (_, __, ___) => controller.scaleState =
                    controller.scaleState == PhotoViewScaleState.initial
                        ? PhotoViewScaleState.covering
                        : PhotoViewScaleState.initial,
                errorBuilder: (_, __, ___) => ImageByBlurHashOrBase64(
                  imageData: message.thumbImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _copyUrl(BuildContext context, String? filePath) async {
  if (filePath?.isEmpty ?? true) {
    return showToastFailed(context, null);
  }
  try {
    await Pasteboard.writeUrl(
      Uri.file(filePath!, windows: Platform.isWindows).toString(),
    );
  } catch (error) {
    await showToastFailed(context, error);
    return;
  }
  showToastSuccessful(context);
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
