// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(arg0) => "等待${arg0}上线后建立加密会话。";

  static String m1(arg0, arg1) => "${arg0}添加了${arg1}";

  static String m2(arg0) => "${arg0}离开了群组";

  static String m3(arg0) => "${arg0}通过邀请链接加入群组";

  static String m4(arg0, arg1) => "${arg0}移除了${arg1}";

  static String m5(arg0, arg1) => "${arg0}置顶了${arg1}";

  static String m6(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} 会话', other: '${arg0} 会话')}";

  static String m7(arg0) => "${arg0}的圈子";

  static String m8(arg0) => "Mixin ID: ${arg0}";

  static String m9(arg0) => "删除会话：${arg0}";

  static String m10(arg0) => "${arg0}创建了这个群组";

  static String m11(arg0) => "确定删除${arg0}圈子吗？";

  static String m12(arg0) => "错误 ${arg0}：请重新登录";

  static String m13(arg0) => "错误 ${arg0}：请求数据不合法";

  static String m14(arg0) => "错误 ${arg0}：区块链同步异常，请稍后重试";

  static String m15(arg0) => "错误 ${arg0}：群组已满";

  static String m16(arg0) => "错误 ${arg0}：余额不足";

  static String m17(arg0, arg1) => "错误 ${arg0}：手续费不足。请确保钱包至少有 ${arg1} 当作手续费。";

  static String m18(arg0, arg1, arg2) =>
      "错误 ${arg0}：地址格式错误。请输入正确的 ${arg1} ${arg2} 的地址！";

  static String m19(arg0) => "错误 ${arg0}：地址格式错误。";

  static String m20(arg0) => "错误 ${arg0}：发送验证码太频繁，请稍后再试";

  static String m21(arg0) => "错误 ${arg0}：紧急联系人不正确";

  static String m22(arg0) => "错误 ${arg0}：无效密码格式";

  static String m23(arg0) => "错误 ${arg0}：没有找到相应的信息";

  static String m24(arg0) => "错误 ${arg0}: 已达到上限";

  static String m25(arg0, arg1) => "错误 ${arg0}：请更新 Mixin(${arg1}) 至最新版。";

  static String m26(arg0) => "错误 ${arg0}：手机号码不合法";

  static String m27(arg0) => "错误 ${arg0}：发送短信失败";

  static String m28(arg0) => "错误 ${arg0}：验证码已过期";

  static String m29(arg0) => "错误 ${arg0}：验证码错误";

  static String m30(arg0) => "错误 ${arg0}：PIN 不正确";

  static String m31(count, arg0, arg1) =>
      "${Intl.plural(count, one: '错误 ${arg0}：PIN 不正确。你还有${arg1}次机会，使用完需等待24小时后再次尝试。', other: '错误 ${arg0}：PIN 不正确。你还有${arg1}次机会，使用完需等待24小时后再次尝试。')}";

  static String m32(arg0) => "错误 ${arg0}：验证失败";

  static String m33(arg0) => "服务器出错，请稍后重试: ${arg0}";

  static String m34(arg0) => "错误 ${arg0}：请求过于频繁";

  static String m35(arg0) => "错误 ${arg0}：贴纸数已达上限";

  static String m36(arg0) => "错误 ${arg0}：转账金额太小";

  static String m37(arg0) => "错误 ${arg0}：提现金额太小";

  static String m38(arg0) => "错误：${arg0}";

  static String m39(arg0) => "错误：${arg0}";

  static String m40(arg0) => "错误 ${arg0}：电话号码已经被占用。";

  static String m41(arg0) => "ERROR ${arg0}: 提现备注格式不正确";

  static String m42(arg0) => "发送消息至 ${arg0}";

  static String m43(arg0) => "移除 ${arg0}";

  static String m44(count) =>
      "${Intl.plural(count, one: '%d 小时', other: '%d 小时')}";

  static String m45(arg0) => "${arg0} 加入";

  static String m46(arg0) => "您的账户将于 ${arg0} 被删除，如果您继续登录，删除您账户的请求将被取消。";

  static String m47(arg0) => "我们将发送4位验证码到手机 ${arg0}, 请在下一个页面输入";

  static String m48(arg0) => "请输入发送至以下号码的 4 位验证码： ${arg0}";

  static String m49(arg0) => "我的 Mixin ID: ${arg0}";

  static String m50(arg0, arg1) =>
      "发现新版本 Mixin Messenger ${arg0}，当前版本为 ${arg1}。是否要下载最新的版本？";

  static String m51(arg0) => "${arg0}现在是管理员";

  static String m52(arg0) => "${arg0} 位群组成员";

  static String m53(count, arg0) =>
      "${Intl.plural(count, one: '${arg0}条置顶消息', other: '${arg0}条置顶消息')}";

  static String m54(arg0) => "${arg0} 秒后重新发送验证码";

  static String m55(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} 条相关的消息', other: '${arg0} 条相关的消息')}";

  static String m56(arg0) => "无法打开文件：${arg0}";

  static String m57(arg0) => "价值 ${arg0}";

  static String m58(arg0) => "当时价值 ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("一条消息"),
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("禁止访问"),
        "add": MessageLookupByLibrary.simpleMessage("添加"),
        "addBotWithPlus": MessageLookupByLibrary.simpleMessage("+ 添加机器人"),
        "addContact": MessageLookupByLibrary.simpleMessage("添加联系人"),
        "addContactWithPlus": MessageLookupByLibrary.simpleMessage("+ 添加联系人"),
        "addFile": MessageLookupByLibrary.simpleMessage("添加文件"),
        "addGroupDescription": MessageLookupByLibrary.simpleMessage("添加群公告"),
        "addParticipants": MessageLookupByLibrary.simpleMessage("添加成员"),
        "addPeopleSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID 或手机号"),
        "addSticker": MessageLookupByLibrary.simpleMessage("添加贴纸"),
        "addStickerFailed": MessageLookupByLibrary.simpleMessage("添加贴纸失败"),
        "addStickers": MessageLookupByLibrary.simpleMessage("添加所有表情"),
        "added": MessageLookupByLibrary.simpleMessage("已添加"),
        "admin": MessageLookupByLibrary.simpleMessage("管理员"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("分享了一个联系人"),
        "allChats": MessageLookupByLibrary.simpleMessage("全部聊天"),
        "appCardShareDisallow":
            MessageLookupByLibrary.simpleMessage("该链接已被设置为不允许分享"),
        "appearance": MessageLookupByLibrary.simpleMessage("外观"),
        "archivedFolder": MessageLookupByLibrary.simpleMessage("存档文件夹"),
        "assetType": MessageLookupByLibrary.simpleMessage("资产类型"),
        "audio": MessageLookupByLibrary.simpleMessage("语音"),
        "audios": MessageLookupByLibrary.simpleMessage("音频"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("自动备份"),
        "avatar": MessageLookupByLibrary.simpleMessage("头像"),
        "backup": MessageLookupByLibrary.simpleMessage("备份"),
        "biography": MessageLookupByLibrary.simpleMessage("简介"),
        "block": MessageLookupByLibrary.simpleMessage("屏蔽用户"),
        "bots": MessageLookupByLibrary.simpleMessage("机器人"),
        "canNotRecognizeQrCode":
            MessageLookupByLibrary.simpleMessage("无法识别二维码"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "card": MessageLookupByLibrary.simpleMessage("卡片"),
        "change": MessageLookupByLibrary.simpleMessage("更改"),
        "chatAppReceptionTitle":
            MessageLookupByLibrary.simpleMessage("点击按钮使用机器人"),
        "chatBackup": MessageLookupByLibrary.simpleMessage("聊天记录备份"),
        "chatDecryptionFailedHint": m0,
        "chatGroupAdd": m1,
        "chatGroupExit": m2,
        "chatGroupJoin": m3,
        "chatGroupRemove": m4,
        "chatHintE2e": MessageLookupByLibrary.simpleMessage("端对端加密"),
        "chatNotSupportUriOnPhone":
            MessageLookupByLibrary.simpleMessage("不支持此链接，请在手机上查看。"),
        "chatNotSupportViewOnPhone":
            MessageLookupByLibrary.simpleMessage("不支持此类型消息，请在手机上查看。"),
        "chatPinMessage": m5,
        "checkNewVersion": MessageLookupByLibrary.simpleMessage("检查新版本"),
        "circleSubtitle": m6,
        "circleTitle": m7,
        "circles": MessageLookupByLibrary.simpleMessage("圈子"),
        "clear": MessageLookupByLibrary.simpleMessage("清理"),
        "clearChat": MessageLookupByLibrary.simpleMessage("清除聊天记录"),
        "clickToReloadQrcode":
            MessageLookupByLibrary.simpleMessage("点击重新加载二维码"),
        "closeWindow": MessageLookupByLibrary.simpleMessage("关闭窗口"),
        "collapse": MessageLookupByLibrary.simpleMessage("折叠"),
        "confirm": MessageLookupByLibrary.simpleMessage("确认"),
        "contact": MessageLookupByLibrary.simpleMessage("联系人"),
        "contactMixinId": m8,
        "contactMuteTitle": MessageLookupByLibrary.simpleMessage("静音通知"),
        "contacts": MessageLookupByLibrary.simpleMessage("联系人"),
        "contentTooLong": MessageLookupByLibrary.simpleMessage("内容过长"),
        "contentVoice": MessageLookupByLibrary.simpleMessage("[语音电话]"),
        "continueText": MessageLookupByLibrary.simpleMessage("继续"),
        "conversation": MessageLookupByLibrary.simpleMessage("会话"),
        "conversationDeleteTitle": m9,
        "copy": MessageLookupByLibrary.simpleMessage("复制"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("复制邀请链接"),
        "create": MessageLookupByLibrary.simpleMessage("创建"),
        "createCircle": MessageLookupByLibrary.simpleMessage("新建圈子"),
        "createConversation": MessageLookupByLibrary.simpleMessage("新建会话"),
        "createGroup": MessageLookupByLibrary.simpleMessage("新建群组"),
        "createdThisGroup": m10,
        "dark": MessageLookupByLibrary.simpleMessage("深色"),
        "dataAndStorageUsage": MessageLookupByLibrary.simpleMessage("数据与存储空间"),
        "dataError": MessageLookupByLibrary.simpleMessage("数据错误"),
        "dataLoading": MessageLookupByLibrary.simpleMessage("数据加载中，请稍后"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("删除聊天"),
        "deleteChatDescription":
            MessageLookupByLibrary.simpleMessage("删除会话只会删除此设备的聊天记录，不会影响其他设备。"),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("删除圈子"),
        "deleteForEveryone": MessageLookupByLibrary.simpleMessage("撤回"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("删除群组"),
        "deleteTheCircle": m11,
        "developer": MessageLookupByLibrary.simpleMessage("开发者"),
        "dismissAsAdmin": MessageLookupByLibrary.simpleMessage("撤销管理员身份"),
        "done": MessageLookupByLibrary.simpleMessage("完成"),
        "download": MessageLookupByLibrary.simpleMessage("下载"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("下载链接："),
        "dragAndDropFileHere": MessageLookupByLibrary.simpleMessage("拖放文件到此处"),
        "durationIsTooShort": MessageLookupByLibrary.simpleMessage("时间太短"),
        "editCircleName": MessageLookupByLibrary.simpleMessage("编辑名称"),
        "editGroupDescription": MessageLookupByLibrary.simpleMessage("编辑群公告"),
        "editGroupName": MessageLookupByLibrary.simpleMessage("编辑名称"),
        "editImageClearWarning":
            MessageLookupByLibrary.simpleMessage("退出将会清除此次所有的改动。"),
        "editName": MessageLookupByLibrary.simpleMessage("修改昵称"),
        "editProfile": MessageLookupByLibrary.simpleMessage("编辑资料"),
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("输入你的手机号码"),
        "errorAddressExists":
            MessageLookupByLibrary.simpleMessage("地址不存在，请确保地址是否添加成功"),
        "errorAddressNotSync":
            MessageLookupByLibrary.simpleMessage("地址刷新失败，请重试"),
        "errorAssetExists": MessageLookupByLibrary.simpleMessage("没有相关资产"),
        "errorAuthentication": m12,
        "errorBadData": m13,
        "errorBlockchain": m14,
        "errorConnectionTimeout":
            MessageLookupByLibrary.simpleMessage("网络连接超时"),
        "errorFullGroup": m15,
        "errorInsufficientBalance": m16,
        "errorInsufficientTransactionFeeWithAmount": m17,
        "errorInvalidAddress": m18,
        "errorInvalidAddressPlain": m19,
        "errorInvalidCodeTooFrequent": m20,
        "errorInvalidEmergencyContact": m21,
        "errorInvalidPinFormat": m22,
        "errorNetworkTaskFailed":
            MessageLookupByLibrary.simpleMessage("网络连接失败。检查或切换网络，然后重试"),
        "errorNotFound": m23,
        "errorNotSupportedAudioFormat":
            MessageLookupByLibrary.simpleMessage("不支持的音频格式，请用其他app打开。"),
        "errorNumberReachedLimit": m24,
        "errorOldVersion": m25,
        "errorOpenLocation": MessageLookupByLibrary.simpleMessage("无法找到地图应用"),
        "errorPermission": MessageLookupByLibrary.simpleMessage("请开启相关权限"),
        "errorPhoneInvalidFormat": m26,
        "errorPhoneSmsDelivery": m27,
        "errorPhoneVerificationCodeExpired": m28,
        "errorPhoneVerificationCodeInvalid": m29,
        "errorPinCheckTooManyRequest":
            MessageLookupByLibrary.simpleMessage("你已经尝试了超过5次，请等待24小时后再次尝试。"),
        "errorPinIncorrect": m30,
        "errorPinIncorrectWithTimes": m31,
        "errorRecaptchaIsInvalid": m32,
        "errorServer5xxCode": m33,
        "errorTooManyRequest": m34,
        "errorTooManyStickers": m35,
        "errorTooSmallTransferAmount": m36,
        "errorTooSmallWithdrawAmount": m37,
        "errorTranscriptForward":
            MessageLookupByLibrary.simpleMessage("请在所有附件下载完成之后再转发"),
        "errorUnableToOpenMedia":
            MessageLookupByLibrary.simpleMessage("无法找到能打开该媒体的应用"),
        "errorUnknownWithCode": m38,
        "errorUnknownWithMessage": m39,
        "errorUsedPhone": m40,
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("用户数据不合法"),
        "errorWithdrawalMemoFormatIncorrect": m41,
        "exit": MessageLookupByLibrary.simpleMessage("退出"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("退出群组"),
        "failed": MessageLookupByLibrary.simpleMessage("失败"),
        "file": MessageLookupByLibrary.simpleMessage("文件"),
        "fileChooserError": MessageLookupByLibrary.simpleMessage("文件选择错误"),
        "fileDoesNotExist": MessageLookupByLibrary.simpleMessage("文件不存在"),
        "fileError": MessageLookupByLibrary.simpleMessage("文件错误"),
        "files": MessageLookupByLibrary.simpleMessage("文档"),
        "followSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("关注我们的 Facebook"),
        "followUsOnTwitter":
            MessageLookupByLibrary.simpleMessage("关注我们的 Twitter"),
        "formatNotSupported": MessageLookupByLibrary.simpleMessage("不支持该格式"),
        "forward": MessageLookupByLibrary.simpleMessage("转发"),
        "from": MessageLookupByLibrary.simpleMessage("来自"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("来自:"),
        "groupCantSend":
            MessageLookupByLibrary.simpleMessage("您不能发送消息，因为您已经不再是此群组成员。"),
        "groupName": MessageLookupByLibrary.simpleMessage("群组名称"),
        "groupParticipants": MessageLookupByLibrary.simpleMessage("群成员"),
        "groupPopMenuMessage": m42,
        "groupPopMenuRemove": m43,
        "groups": MessageLookupByLibrary.simpleMessage("群组"),
        "groupsInCommon": MessageLookupByLibrary.simpleMessage("共同群组"),
        "help": MessageLookupByLibrary.simpleMessage("帮助"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("帮助中心"),
        "hideMixin": MessageLookupByLibrary.simpleMessage("隐藏 Mixin"),
        "hour": m44,
        "ignoreThisVersion": MessageLookupByLibrary.simpleMessage("忽略这次版本更新"),
        "image": MessageLookupByLibrary.simpleMessage("图片"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("包括文件"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("包括视频"),
        "initializing": MessageLookupByLibrary.simpleMessage("初始化…"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "Mixin 使用者可以使用此链接加入这个群组，请只跟您信任的人共享链接。"),
        "inviteToGroupViaLink": MessageLookupByLibrary.simpleMessage("群邀请链接"),
        "joinGroupWithPlus": MessageLookupByLibrary.simpleMessage("+ 加入群组"),
        "joinedIn": m45,
        "landingDeleteContent": m46,
        "landingInvitationDialogContent": m47,
        "landingValidationTitle": m48,
        "learnMore": MessageLookupByLibrary.simpleMessage("了解更多"),
        "less": MessageLookupByLibrary.simpleMessage("更少"),
        "light": MessageLookupByLibrary.simpleMessage("浅色"),
        "live": MessageLookupByLibrary.simpleMessage("直播"),
        "loading": MessageLookupByLibrary.simpleMessage("正在加载..."),
        "loadingTime":
            MessageLookupByLibrary.simpleMessage("检测到系统时间异常，请校正后再继续使用"),
        "locateToChat": MessageLookupByLibrary.simpleMessage("定位到聊天"),
        "location": MessageLookupByLibrary.simpleMessage("位置"),
        "logIn": MessageLookupByLibrary.simpleMessage("登录"),
        "loginAndAbortAccountDeletion":
            MessageLookupByLibrary.simpleMessage("继续登录并放弃删除账户"),
        "loginByQrcode":
            MessageLookupByLibrary.simpleMessage("通过二维码登录 Mixin Messenger"),
        "loginByQrcodeTips": MessageLookupByLibrary.simpleMessage(
            "打开手机上的 Mixin Messenger，扫描屏幕上的二维码，确认登录。"),
        "makeGroupAdmin": MessageLookupByLibrary.simpleMessage("设定为群组管理员"),
        "media": MessageLookupByLibrary.simpleMessage("媒体"),
        "memo": MessageLookupByLibrary.simpleMessage("备注"),
        "messageE2ee":
            MessageLookupByLibrary.simpleMessage("此对话中的消息使用端对端加密。点击了解更多。"),
        "messageNotFound": MessageLookupByLibrary.simpleMessage("找不到该消息"),
        "messageNotSupport":
            MessageLookupByLibrary.simpleMessage("不支持此类型消息。请升级 Mixin 查看。"),
        "messagePreview": MessageLookupByLibrary.simpleMessage("消息预览"),
        "messagePreviewDescription":
            MessageLookupByLibrary.simpleMessage("预览新消息通知中的消息文本。"),
        "messages": MessageLookupByLibrary.simpleMessage("消息"),
        "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger 桌面"),
        "more": MessageLookupByLibrary.simpleMessage("更多"),
        "mute": MessageLookupByLibrary.simpleMessage("静音"),
        "muted": MessageLookupByLibrary.simpleMessage("已静音"),
        "myMixinId": m49,
        "myStickers": MessageLookupByLibrary.simpleMessage("我的表情"),
        "na": MessageLookupByLibrary.simpleMessage("暂无价格"),
        "name": MessageLookupByLibrary.simpleMessage("名称"),
        "networkError": MessageLookupByLibrary.simpleMessage("网络错误"),
        "newVersionAvailable": MessageLookupByLibrary.simpleMessage("发现新版本"),
        "newVersionDescription": m50,
        "next": MessageLookupByLibrary.simpleMessage("下一步"),
        "nextConversation": MessageLookupByLibrary.simpleMessage("下一个会话"),
        "noAudio": MessageLookupByLibrary.simpleMessage("没有音频"),
        "noCamera": MessageLookupByLibrary.simpleMessage("没有相机"),
        "noData": MessageLookupByLibrary.simpleMessage("没有数据"),
        "noFile": MessageLookupByLibrary.simpleMessage("没有文件"),
        "noLink": MessageLookupByLibrary.simpleMessage("没有链接"),
        "noMedia": MessageLookupByLibrary.simpleMessage("没有媒体"),
        "noNetworkConnection": MessageLookupByLibrary.simpleMessage("无网络连接"),
        "noPost": MessageLookupByLibrary.simpleMessage("没有文章"),
        "noResult": MessageLookupByLibrary.simpleMessage("没有结果"),
        "notFound": MessageLookupByLibrary.simpleMessage("没有找到相应的消息"),
        "notificationContent":
            MessageLookupByLibrary.simpleMessage("不再遗漏好友的消息。"),
        "notificationPermissionManually":
            MessageLookupByLibrary.simpleMessage("未允许通知，请到通知设置开启。"),
        "notifications": MessageLookupByLibrary.simpleMessage("通知"),
        "nowAnAddmin": m51,
        "oneHour": MessageLookupByLibrary.simpleMessage("1 小时"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1 星期"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1 年"),
        "openHomePage": MessageLookupByLibrary.simpleMessage("打开主页"),
        "openLogDirectory": MessageLookupByLibrary.simpleMessage("打开日志文件夹"),
        "originalImage": MessageLookupByLibrary.simpleMessage("原图"),
        "owner": MessageLookupByLibrary.simpleMessage("群主"),
        "participantsCount": m52,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("手机号码"),
        "photos": MessageLookupByLibrary.simpleMessage("照片"),
        "pickAConversation":
            MessageLookupByLibrary.simpleMessage("选择一个对话，开始发送信息"),
        "pinTitle": MessageLookupByLibrary.simpleMessage("置顶"),
        "pinnedMessageTitle": m53,
        "post": MessageLookupByLibrary.simpleMessage("文章"),
        "preferences": MessageLookupByLibrary.simpleMessage("偏好设置"),
        "previousConversation": MessageLookupByLibrary.simpleMessage("上一个会话"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "quickSearch": MessageLookupByLibrary.simpleMessage("快速搜索"),
        "quitMixin": MessageLookupByLibrary.simpleMessage("退出 Mixin"),
        "recaptchaTimeout": MessageLookupByLibrary.simpleMessage("验证超时"),
        "receiver": MessageLookupByLibrary.simpleMessage("至"),
        "recentChats": MessageLookupByLibrary.simpleMessage("最近聊天"),
        "reedit": MessageLookupByLibrary.simpleMessage("重新编辑"),
        "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
        "removeBot": MessageLookupByLibrary.simpleMessage("删除机器人"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("从圈子里移除对话"),
        "removeContact": MessageLookupByLibrary.simpleMessage("删除联系人"),
        "removeStickers": MessageLookupByLibrary.simpleMessage("移除所有表情"),
        "reply": MessageLookupByLibrary.simpleMessage("回复"),
        "report": MessageLookupByLibrary.simpleMessage("举报"),
        "reportAndBlock": MessageLookupByLibrary.simpleMessage("举报并屏蔽？"),
        "resendCode": MessageLookupByLibrary.simpleMessage("重发验证码"),
        "resendCodeIn": m54,
        "reset": MessageLookupByLibrary.simpleMessage("重置"),
        "resetLink": MessageLookupByLibrary.simpleMessage("重置邀请链接"),
        "retryUploadFailed": MessageLookupByLibrary.simpleMessage("重新上传失败。"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saveAs": MessageLookupByLibrary.simpleMessage("另存为"),
        "saveToCameraRoll": MessageLookupByLibrary.simpleMessage("保存到相册"),
        "sayHi": MessageLookupByLibrary.simpleMessage("打招呼"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "警告：此账号被大量用户举报，请谨防网络诈骗，注意个人财产安全"),
        "search": MessageLookupByLibrary.simpleMessage("搜索"),
        "searchContact": MessageLookupByLibrary.simpleMessage("搜索用户"),
        "searchConversation": MessageLookupByLibrary.simpleMessage("搜索聊天记录"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage("找不到联系人或消息。"),
        "searchRelatedMessage": m55,
        "send": MessageLookupByLibrary.simpleMessage("发送"),
        "sendArchived": MessageLookupByLibrary.simpleMessage("打包成 zip 发送"),
        "sendQuickly": MessageLookupByLibrary.simpleMessage("快速发送"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("发送原始文件"),
        "sendWithoutSound": MessageLookupByLibrary.simpleMessage("静音发送"),
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID, 昵称"),
        "share": MessageLookupByLibrary.simpleMessage("分享"),
        "shareApps": MessageLookupByLibrary.simpleMessage("分享的应用"),
        "shareContact": MessageLookupByLibrary.simpleMessage("分享联系人"),
        "shareError": MessageLookupByLibrary.simpleMessage("分享出错"),
        "shareLink": MessageLookupByLibrary.simpleMessage("分享邀请链接"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("媒体内容"),
        "show": MessageLookupByLibrary.simpleMessage("显示"),
        "showAvatar": MessageLookupByLibrary.simpleMessage("显示头像"),
        "showMixin": MessageLookupByLibrary.simpleMessage("显示 Mixin"),
        "signIn": MessageLookupByLibrary.simpleMessage("登录"),
        "signOut": MessageLookupByLibrary.simpleMessage("登出"),
        "signWithPhoneNumber": MessageLookupByLibrary.simpleMessage("通过手机号登录"),
        "signWithQrcode": MessageLookupByLibrary.simpleMessage("通过二维码登录"),
        "sticker": MessageLookupByLibrary.simpleMessage("贴纸"),
        "stickerAlbumDetail": MessageLookupByLibrary.simpleMessage("表情详情"),
        "stickerStore": MessageLookupByLibrary.simpleMessage("表情商店"),
        "storageAutoDownloadDescription":
            MessageLookupByLibrary.simpleMessage("更改媒体的自动下载设置。"),
        "storageUsage": MessageLookupByLibrary.simpleMessage("储存空间"),
        "strangerHint": MessageLookupByLibrary.simpleMessage("对方不是你的联系人"),
        "strangers": MessageLookupByLibrary.simpleMessage("陌生人"),
        "successful": MessageLookupByLibrary.simpleMessage("成功"),
        "termsOfService": MessageLookupByLibrary.simpleMessage("服务条款"),
        "text": MessageLookupByLibrary.simpleMessage("文字"),
        "theme": MessageLookupByLibrary.simpleMessage("主题"),
        "thisMessageWasDeleted": MessageLookupByLibrary.simpleMessage("此消息已撤回"),
        "time": MessageLookupByLibrary.simpleMessage("时间"),
        "today": MessageLookupByLibrary.simpleMessage("今天"),
        "toggleChatInfo": MessageLookupByLibrary.simpleMessage("展开/关闭会话信息"),
        "transactionId": MessageLookupByLibrary.simpleMessage("交易编号"),
        "transactions": MessageLookupByLibrary.simpleMessage("转账记录"),
        "transcript": MessageLookupByLibrary.simpleMessage("聊天记录"),
        "transfer": MessageLookupByLibrary.simpleMessage("转账"),
        "turnOnNotifications": MessageLookupByLibrary.simpleMessage("打开通知"),
        "typeMessage": MessageLookupByLibrary.simpleMessage("输入消息"),
        "unableToOpenFile": m56,
        "unblock": MessageLookupByLibrary.simpleMessage("解除屏蔽"),
        "unmute": MessageLookupByLibrary.simpleMessage("取消静音"),
        "unpin": MessageLookupByLibrary.simpleMessage("取消置顶"),
        "unpinAllMessages": MessageLookupByLibrary.simpleMessage("取消所有置顶消息"),
        "unpinAllMessagesConfirmation":
            MessageLookupByLibrary.simpleMessage("确定取消置顶所有消息么？"),
        "unreadMessages": MessageLookupByLibrary.simpleMessage("未读消息"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("找不到这个用户"),
        "valueNow": m57,
        "valueThen": m58,
        "video": MessageLookupByLibrary.simpleMessage("视频"),
        "videos": MessageLookupByLibrary.simpleMessage("视频"),
        "webview2RuntimeInstallDescription":
            MessageLookupByLibrary.simpleMessage(
                "该设备暂未安装 WebView2 组件，请先下载并安装 WebView2 Runtime。"),
        "webviewRuntimeUnavailable":
            MessageLookupByLibrary.simpleMessage("WebView2 组件不可用"),
        "whatsYourName": MessageLookupByLibrary.simpleMessage("你的名字?"),
        "window": MessageLookupByLibrary.simpleMessage("窗口"),
        "writeCircles": MessageLookupByLibrary.simpleMessage("管理圈子"),
        "you": MessageLookupByLibrary.simpleMessage("你"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("你撤回了一条消息")
      };
}
