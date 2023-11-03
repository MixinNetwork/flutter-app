import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/resources.dart';
import '../enum/message_category.dart';
import '../generated/l10n.dart';
import '../widgets/message/item/action/action_data.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import 'extension/extension.dart';

String? messagePreviewOptimize(
  MessageStatus? messageStatus,
  String? messageCategory,
  String? content, [
  bool isCurrentUser = false,
  bool isGroup = false,
  String? senderFullName,
]) {
  String? _content;

  final trimContent = content?.trim();
  if (messageCategory.isIllegalMessageCategory) {
    _content = Localization.current.messageNotSupport;
  } else if (messageStatus == MessageStatus.failed) {
    _content = Localization.current.waitingForThisMessage;
  } else if (messageStatus == MessageStatus.unknown) {
    _content = Localization.current.messageNotSupport;
  } else if (messageCategory.isText) {
    _content = trimContent;
  } else if (messageCategory == MessageCategory.systemAccountSnapshot ||
      messageCategory == MessageCategory.systemSafeSnapshot) {
    _content = '[${Localization.current.transfer}]';
  } else if (messageCategory.isSticker) {
    _content = '[${Localization.current.sticker}]';
  } else if (messageCategory.isImage) {
    _content = '[${Localization.current.image}]';
  } else if (messageCategory.isVideo) {
    _content = '[${Localization.current.video}]';
  } else if (messageCategory.isLive) {
    _content = '[${Localization.current.live}]';
  } else if (messageCategory.isData) {
    _content = '[${Localization.current.file}]';
  } else if (messageCategory.isPost) {
    _content = trimContent?.postOptimizeMarkdown ?? Localization.current.post;
  } else if (messageCategory.isLocation) {
    _content = '[${Localization.current.location}]';
  } else if (messageCategory.isAudio) {
    _content = '[${Localization.current.audio}]';
  } else if (messageCategory == MessageCategory.appButtonGroup) {
    _content = '';
    try {
      final list = jsonDecode(trimContent!) as List<dynamic>;
      _content = list
          .map((e) => ActionData.fromJson(e as Map<String, dynamic>))
          // ignore: avoid_dynamic_calls
          .map((e) => '[${e.label}]')
          .join();
    } catch (_) {}
  } else if (messageCategory == MessageCategory.appCard) {
    _content = '[${Localization.current.card}]';
    try {
      _content =
          '[${AppCardData.fromJson(jsonDecode(trimContent!) as Map<String, dynamic>).title}]';
    } catch (_) {}
  } else if (messageCategory.isContact) {
    _content = '[${Localization.current.contact}]';
  } else if (messageCategory.isCallMessage) {
    _content = Localization.current.contentVoice;
  } else if (messageCategory.isRecall) {
    _content =
        '[${isCurrentUser ? Localization.current.youDeletedThisMessage : Localization.current.thisMessageWasDeleted}]';
  } else if (messageCategory.isTranscript) {
    _content = '[${Localization.current.transcript}]';
  } else {
    _content = Localization.current.messageNotSupport;
  }

  if ((_content?.isNotEmpty ?? false) && isGroup) {
    final sender =
        isCurrentUser ? Localization.current.you : senderFullName ?? '';
    _content = '$sender: $_content';
  }

  return _content;
}

String? messagePreviewIcon(
  MessageStatus? messageStatus,
  String? messageCategory,
) {
  String? icon;

  if (messageStatus == MessageStatus.failed) {
  } else if (messageCategory.isText) {
  } else if (messageCategory == MessageCategory.systemAccountSnapshot ||
      messageCategory == MessageCategory.systemSafeSnapshot) {
    icon = Resources.assetsImagesTransferSvg;
  } else if (messageCategory.isSticker) {
    icon = Resources.assetsImagesStickerSvg;
  } else if (messageCategory.isImage) {
    icon = Resources.assetsImagesImageSvg;
  } else if (messageCategory.isVideo) {
    icon = Resources.assetsImagesVideoSvg;
  } else if (messageCategory.isLive) {
    icon = Resources.assetsImagesLiveSvg;
  } else if (messageCategory.isData) {
    icon = Resources.assetsImagesFileSvg;
  } else if (messageCategory.isPost) {
    icon = Resources.assetsImagesFileSvg;
  } else if (messageCategory.isLocation) {
    icon = Resources.assetsImagesLocationSvg;
  } else if (messageCategory.isAudio) {
    icon = Resources.assetsImagesAudioSvg;
  } else if (messageCategory == MessageCategory.appButtonGroup) {
    icon = Resources.assetsImagesAppButtonSvg;
  } else if (messageCategory == MessageCategory.appCard) {
    icon = Resources.assetsImagesAppButtonSvg;
  } else if (messageCategory.isContact) {
    icon = Resources.assetsImagesContactSvg;
  } else if (messageCategory.isCallMessage) {
    icon = Resources.assetsImagesVideoCallSvg;
  } else if (messageCategory.isRecall) {
    icon = Resources.assetsImagesRecallSvg;
  } else if (messageCategory.isTranscript) {
    icon = Resources.assetsImagesFileSvg;
  }
  return icon;
}
