import '../constants/resources.dart';
import '../db/extension/message_category.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../generated/l10n.dart';
import '../widgets/message/item/action/action_data.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import 'load_balancer_utils.dart';
import 'markdown.dart';

Future<String?> messagePreviewOptimize(
  MessageStatus? messageStatus,
  MessageCategory? messageCategory,
  String? content, [
  bool isCurrentUser = false,
  bool isGroup = false,
  String? senderFullName,
]) async {
  String? _content;

  final trimContent = content?.trim();

  if (messageStatus == MessageStatus.failed) {
    _content = Localization.current.waitingForThisMessage;
  } else if (messageCategory.isText) {
    _content = trimContent;
  } else if (messageCategory == MessageCategory.systemAccountSnapshot) {
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
    _content = _content?.postOptimizeMarkdown ?? Localization.current.post;
  } else if (messageCategory.isLocation) {
    _content = '[${Localization.current.location}]';
  } else if (messageCategory.isAudio) {
    _content = '[${Localization.current.audio}]';
  } else if (messageCategory == MessageCategory.appButtonGroup) {
    _content = '';
    if (trimContent != null) {
      // ignore: avoid_dynamic_calls
      _content = (await jsonDecodeWithIsolate(trimContent))
          .map((e) => ActionData.fromJson(e))
          // ignore: avoid_dynamic_calls
          .map((e) => '[${e.label}]')
          .join();
    }
  } else if (messageCategory == MessageCategory.appCard) {
    _content = '';
    if (trimContent != null) {
      _content =
          AppCardData.fromJson(await jsonDecodeWithIsolate(trimContent)).title;
    }
  } else if (messageCategory.isContact) {
    _content = '[${Localization.current.contact}]';
  } else if (messageCategory.isCallMessage) {
    _content = '[${Localization.current.videoCall}]';
  } else if (messageCategory.isRecall) {
    _content =
        '[${isCurrentUser ? Localization.current.chatRecallMe : Localization.current.chatRecallDelete}]';
  } else {
    _content = Localization.current.chatNotSupport;
  }

  if ((_content?.isNotEmpty ?? false) && isGroup) {
    late String sender;
    if (isCurrentUser) {
      sender = Localization.current.youStart;
    } else {
      sender = senderFullName ?? '';
    }
    _content = '$sender: $_content';
  }

  return _content;
}

String? messagePreviewIcon(
  MessageStatus? messageStatus,
  MessageCategory? messageCategory,
) {
  String? icon;

  if (messageStatus == MessageStatus.failed) {
    icon = Resources.assetsImagesSendingSvg;
  } else if (messageCategory.isText) {
  } else if (messageCategory == MessageCategory.systemAccountSnapshot) {
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
  }
  return icon;
}
