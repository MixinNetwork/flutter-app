import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/load_balancer_utils.dart';
import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_app/widgets/message/item/action_card/action_card_data.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:flutter_app/utils/markdown.dart';
import 'package:tuple/tuple.dart';

Future<Tuple2<String?, String?>> messageOptimize(
  MessageStatus? messageStatus,
  MessageCategory? messageCategory,
  String? content, [
  bool isCurrentUser = false,
]) async {
  String? icon;
  String? _content;

  if (messageStatus == MessageStatus.failed) {
    icon = Resources.assetsImagesSendingSvg;
    _content = Localization.current.waitingForThisMessage;
  } else if (messageCategory.isText) {
    // todo markdown and mention
    _content = content;
  } else if (messageCategory == MessageCategory.systemAccountSnapshot) {
    _content = '[${Localization.current.transfer}]';
    icon = Resources.assetsImagesTransferSvg;
  } else if (messageCategory.isSticker) {
    _content = '[${Localization.current.sticker}]';
    icon = Resources.assetsImagesStickerSvg;
  } else if (messageCategory.isImage) {
    _content = '[${Localization.current.image}]';
    icon = Resources.assetsImagesImageSvg;
  } else if (messageCategory.isVideo) {
    _content = '[${Localization.current.video}]';
    icon = Resources.assetsImagesVideoSvg;
  } else if (messageCategory.isLive) {
    _content = '[${Localization.current.live}]';
    icon = Resources.assetsImagesLiveSvg;
  } else if (messageCategory.isData) {
    _content = '[${Localization.current.file}]';
    icon = Resources.assetsImagesFileSvg;
  } else if (messageCategory.isPost) {
    icon = Resources.assetsImagesFileSvg;
    _content = _content!.postOptimizeMarkdown;
  } else if (messageCategory.isLocation) {
    _content = '[${Localization.current.location}]';
    icon = Resources.assetsImagesLocationSvg;
  } else if (messageCategory.isAudio) {
    _content = '[${Localization.current.audio}]';
    icon = Resources.assetsImagesAudioSvg;
  } else if (messageCategory == MessageCategory.appButtonGroup) {
    _content = 'APP_BUTTON_GROUP';
    if (content != null)
      _content = (await LoadBalancerUtils.jsonDecode(content))
          .map((e) => ActionData.fromJson(e))
          .map((e) => '[${e.label}]')
          .join();
    icon = Resources.assetsImagesAppButtonSvg;
  } else if (messageCategory == MessageCategory.appCard) {
    _content = 'APP_CARD';
    if (content != null)
      _content =
          AppCardData.fromJson((await LoadBalancerUtils.jsonDecode(content)))
              .title;
    icon = Resources.assetsImagesAppButtonSvg;
  } else if (messageCategory.isContact) {
    _content = '[${Localization.current.contact}]';
    icon = Resources.assetsImagesContactSvg;
  } else if (messageCategory.isCallMessage) {
    _content = '[${Localization.current.videoCall}]';
    icon = Resources.assetsImagesVideoCallSvg;
  } else if (messageCategory.isRecall) {
    _content =
        '[${isCurrentUser ? Localization.current.chatRecallMe : Localization.current.chatRecallDelete}]';
    icon = Resources.assetsImagesRecallSvg;
  } else {
    _content = Localization.current.chatNotSupport;
    icon = Resources.assetsImagesRecallSvg;
  }

  return Tuple2(icon, _content);
}
