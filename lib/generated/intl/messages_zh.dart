// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(name, addedName) => "${name}添加了${addedName}";

  static String m1(name, groupName) => "${name}创建了群组${groupName}";

  static String m2(name) => "${name}离开了群组";

  static String m3(name) => "${name}通过邀请链接加入群组";

  static String m4(name, removedName) => "${name}移除了${removedName}";

  static String m5(name) => "等待${name}上线后建立加密会话。";

  static String m6(name) => "${name}的圈子";

  static String m7(mixinId) => "Mixin ID: ${mixinId}";

  static String m8(count) => "${count} 个会话";

  static String m10(count) => "${count} 成员";

  static String m11(count) => "${count} 位群组成员";

  static String m12(ID) => "我的 Mixin ID: ${ID}";

  static String m13(name) => "发送消息至 ${name}";

  static String m14(name) => "移除 ${name}";

  static String m15(name) => "确定删除${name}圈子吗？";

  static String m16(date) => "${date}加入";

  static String m17(count) => "共 ${count} 人";

  static String m18(count) => "${count}条置顶消息";

  static String m19(user, preview) => "${user}置顶了${preview}";

  static String m20(count) => "${count} 条相关的消息";

  static String m21(value) => "价值 ${value}";

  static String m22(value) => "当时价值 ${value}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("一条消息"),
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "aboutEncryptedInfo":
            MessageLookupByLibrary.simpleMessage("此对话中的消息使用端对端加密。点击了解更多。"),
        "addAnnouncement": MessageLookupByLibrary.simpleMessage("添加群公告"),
        "addContact": MessageLookupByLibrary.simpleMessage("添加联系人"),
        "appCard": MessageLookupByLibrary.simpleMessage("卡片"),
        "appearance": MessageLookupByLibrary.simpleMessage("显示偏好"),
        "archivedFolder": MessageLookupByLibrary.simpleMessage("存档文件夹"),
        "assetType": MessageLookupByLibrary.simpleMessage("资产类型"),
        "audio": MessageLookupByLibrary.simpleMessage("语音"),
        "audios": MessageLookupByLibrary.simpleMessage("音频"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("自动备份"),
        "backup": MessageLookupByLibrary.simpleMessage("备份"),
        "block": MessageLookupByLibrary.simpleMessage("屏蔽"),
        "botInteractHi": MessageLookupByLibrary.simpleMessage("打招呼"),
        "botInteractInfo": MessageLookupByLibrary.simpleMessage("点击下列按钮与机器人互动"),
        "botInteractOpen": MessageLookupByLibrary.simpleMessage("打开主页"),
        "bots": MessageLookupByLibrary.simpleMessage("机器人"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "change": MessageLookupByLibrary.simpleMessage("更改"),
        "chatBackup": MessageLookupByLibrary.simpleMessage("聊天记录备份"),
        "chatCheckOnPhone":
            MessageLookupByLibrary.simpleMessage("不支持此类型消息，请在手机上查看。"),
        "chatDragHint": MessageLookupByLibrary.simpleMessage("拖放文件到此处"),
        "chatDragMoreFile": MessageLookupByLibrary.simpleMessage("添加文件"),
        "chatGroupAdd": m0,
        "chatGroupCreate": m1,
        "chatGroupExit": m2,
        "chatGroupJoin": m3,
        "chatGroupRemove": m4,
        "chatGroupRole": MessageLookupByLibrary.simpleMessage("你现在成为管理员"),
        "chatInputHint": MessageLookupByLibrary.simpleMessage("端对端加密"),
        "chatLearn": MessageLookupByLibrary.simpleMessage("了解更多"),
        "chatNotFound": MessageLookupByLibrary.simpleMessage("找不到该消息"),
        "chatNotSupport":
            MessageLookupByLibrary.simpleMessage("不支持此类型消息。请升级 Mixin 查看。"),
        "chatRecallDelete": MessageLookupByLibrary.simpleMessage("此消息已撤回"),
        "chatRecallMe": MessageLookupByLibrary.simpleMessage("你撤回了一条消息"),
        "chatTranscript": MessageLookupByLibrary.simpleMessage("聊天记录"),
        "chatWaiting": m5,
        "chatWaitingDesktop": MessageLookupByLibrary.simpleMessage("桌面端"),
        "chats": MessageLookupByLibrary.simpleMessage("全部聊天"),
        "circleTitle": m6,
        "circles": MessageLookupByLibrary.simpleMessage("圈子"),
        "clear": MessageLookupByLibrary.simpleMessage("清除"),
        "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天记录"),
        "collapse": MessageLookupByLibrary.simpleMessage("折叠"),
        "comingSoon": MessageLookupByLibrary.simpleMessage("即将到来..."),
        "confirm": MessageLookupByLibrary.simpleMessage("确定"),
        "contact": MessageLookupByLibrary.simpleMessage("联系人"),
        "contactMixinId": m7,
        "contacts": MessageLookupByLibrary.simpleMessage("联系人"),
        "continueText": MessageLookupByLibrary.simpleMessage("继续"),
        "conversationAddBot": MessageLookupByLibrary.simpleMessage("+ 添加机器人"),
        "conversationAddContact":
            MessageLookupByLibrary.simpleMessage("+ 添加联系人"),
        "conversationCount": m8,
        "conversationName": MessageLookupByLibrary.simpleMessage("群组名称"),
        "conversationParticipantsCount": m10,
        "conversationParticipantsCountDescription": m11,
        "conversations": MessageLookupByLibrary.simpleMessage("会话"),
        "copy": MessageLookupByLibrary.simpleMessage("复制"),
        "create": MessageLookupByLibrary.simpleMessage("创建"),
        "createCircle": MessageLookupByLibrary.simpleMessage("创建圈子"),
        "createConversation": MessageLookupByLibrary.simpleMessage("新建会话"),
        "createGroupConversation": MessageLookupByLibrary.simpleMessage("创建群组"),
        "currentIdentityNumber": m12,
        "dataAndStorageUsage":
            MessageLookupByLibrary.simpleMessage("数据和存储使用情况"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("删除对话"),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("删除圈子"),
        "deleteForEveryone": MessageLookupByLibrary.simpleMessage("撤回"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("删除"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("删除群组"),
        "developer": MessageLookupByLibrary.simpleMessage("开发者"),
        "done": MessageLookupByLibrary.simpleMessage("完成"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("下载链接："),
        "editAnnouncement": MessageLookupByLibrary.simpleMessage("编辑群公告"),
        "editCircle": MessageLookupByLibrary.simpleMessage("管理圈子"),
        "editCircleName": MessageLookupByLibrary.simpleMessage("编辑圈子名称"),
        "editName": MessageLookupByLibrary.simpleMessage("编辑名称"),
        "editProfile": MessageLookupByLibrary.simpleMessage("编辑资料"),
        "exit": MessageLookupByLibrary.simpleMessage("退出"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("退出群组"),
        "extensions": MessageLookupByLibrary.simpleMessage("机器人"),
        "failed": MessageLookupByLibrary.simpleMessage("失败"),
        "file": MessageLookupByLibrary.simpleMessage("文件"),
        "files": MessageLookupByLibrary.simpleMessage("文档"),
        "followFacebook":
            MessageLookupByLibrary.simpleMessage("关注我们的 Facebook"),
        "followTwitter": MessageLookupByLibrary.simpleMessage("关注我们的 Twitter"),
        "forward": MessageLookupByLibrary.simpleMessage("转发"),
        "from": MessageLookupByLibrary.simpleMessage("来自"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("来自: "),
        "goToChat": MessageLookupByLibrary.simpleMessage("定位到聊天"),
        "groupAdd": MessageLookupByLibrary.simpleMessage("添加成员"),
        "groupAdmin": MessageLookupByLibrary.simpleMessage("管理员"),
        "groupCantSendDes":
            MessageLookupByLibrary.simpleMessage("您不能发送消息，因为您已经不再是此群组成员。"),
        "groupInvite": MessageLookupByLibrary.simpleMessage("群邀请链接"),
        "groupInviteCopy": MessageLookupByLibrary.simpleMessage("复制邀请链接"),
        "groupInviteInfo": MessageLookupByLibrary.simpleMessage(
            "Mixin 使用者可以使用此链接加入这个群组，请只跟您信任的人共享链接。"),
        "groupInviteReset": MessageLookupByLibrary.simpleMessage("重置邀请链接"),
        "groupInviteShare": MessageLookupByLibrary.simpleMessage("分享邀请链接"),
        "groupOwner": MessageLookupByLibrary.simpleMessage("群主"),
        "groupParticipants": MessageLookupByLibrary.simpleMessage("群成员"),
        "groupPopMenuDismissAdmin":
            MessageLookupByLibrary.simpleMessage("撤销管理员身份"),
        "groupPopMenuMakeAdmin":
            MessageLookupByLibrary.simpleMessage("设定为群组管理员"),
        "groupPopMenuMessage": m13,
        "groupPopMenuRemoveParticipants": m14,
        "groupSearchParticipants":
            MessageLookupByLibrary.simpleMessage("Mixin ID, 昵称"),
        "groups": MessageLookupByLibrary.simpleMessage("群组"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("帮助中心"),
        "image": MessageLookupByLibrary.simpleMessage("照片"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("包含文件"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("包括视频"),
        "initializing": MessageLookupByLibrary.simpleMessage("初始化"),
        "introduction": MessageLookupByLibrary.simpleMessage("介绍"),
        "joinGroup": MessageLookupByLibrary.simpleMessage("+ 加入群组"),
        "less": MessageLookupByLibrary.simpleMessage("更少"),
        "links": MessageLookupByLibrary.simpleMessage("链接"),
        "live": MessageLookupByLibrary.simpleMessage("Live"),
        "loading": MessageLookupByLibrary.simpleMessage("加载中"),
        "localTimeErrorDescription":
            MessageLookupByLibrary.simpleMessage("检测到系统时间异常，请校正后再继续使用"),
        "location": MessageLookupByLibrary.simpleMessage("位置"),
        "media": MessageLookupByLibrary.simpleMessage("媒体"),
        "memo": MessageLookupByLibrary.simpleMessage("备注"),
        "messagePreview": MessageLookupByLibrary.simpleMessage("消息预览"),
        "messagePreviewDescription":
            MessageLookupByLibrary.simpleMessage("预览新消息通知中的消息文本。"),
        "messages": MessageLookupByLibrary.simpleMessage("消息"),
        "more": MessageLookupByLibrary.simpleMessage("更多"),
        "mute": MessageLookupByLibrary.simpleMessage("静音"),
        "mute1hour": MessageLookupByLibrary.simpleMessage("1 小时"),
        "mute1week": MessageLookupByLibrary.simpleMessage("1 星期"),
        "mute1year": MessageLookupByLibrary.simpleMessage("1 年"),
        "mute8hours": MessageLookupByLibrary.simpleMessage("8 小时"),
        "muteTitle": MessageLookupByLibrary.simpleMessage("静音通知"),
        "muted": MessageLookupByLibrary.simpleMessage("静音"),
        "name": MessageLookupByLibrary.simpleMessage("名字"),
        "networkConnectionFailed":
            MessageLookupByLibrary.simpleMessage("网络连接失败"),
        "next": MessageLookupByLibrary.simpleMessage("下一步"),
        "noAudio": MessageLookupByLibrary.simpleMessage("没有音频"),
        "noData": MessageLookupByLibrary.simpleMessage("没有数据"),
        "noFile": MessageLookupByLibrary.simpleMessage("没有文件"),
        "noLink": MessageLookupByLibrary.simpleMessage("没有链接"),
        "noMedia": MessageLookupByLibrary.simpleMessage("没有媒体"),
        "noPost": MessageLookupByLibrary.simpleMessage("没有文章"),
        "notification": MessageLookupByLibrary.simpleMessage("通知"),
        "notificationPermissionDescription":
            MessageLookupByLibrary.simpleMessage("不再遗漏好友的消息。"),
        "notificationPermissionManually":
            MessageLookupByLibrary.simpleMessage("未允许通知，请到通知设置开启。"),
        "notificationPermissionTitle":
            MessageLookupByLibrary.simpleMessage("打开通知"),
        "pageDeleteCircle": m15,
        "pageEditProfileJoin": m16,
        "pageLandingClickToReload":
            MessageLookupByLibrary.simpleMessage("点击重新加载二维码"),
        "pageLandingLoginMessage": MessageLookupByLibrary.simpleMessage(
            "打开手机上的 Mixin Messenger，扫描屏幕上的二维码，确认登录。"),
        "pageLandingLoginTitle":
            MessageLookupByLibrary.simpleMessage("通过二维码登录 Mixin Messenger"),
        "pageRightEmptyMessage":
            MessageLookupByLibrary.simpleMessage("选择一个对话，开始发送信息"),
        "participantsCount": m17,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("手机号"),
        "photos": MessageLookupByLibrary.simpleMessage("照片"),
        "pin": MessageLookupByLibrary.simpleMessage("置顶"),
        "pinMessageCount": m18,
        "pinned": m19,
        "pleaseWait": MessageLookupByLibrary.simpleMessage("请稍等一下"),
        "post": MessageLookupByLibrary.simpleMessage("文章"),
        "preview": MessageLookupByLibrary.simpleMessage("预览"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "provisioning": MessageLookupByLibrary.simpleMessage("加载中"),
        "recentConversations": MessageLookupByLibrary.simpleMessage("最近聊天"),
        "reedit": MessageLookupByLibrary.simpleMessage("重新编辑"),
        "removeBot": MessageLookupByLibrary.simpleMessage("删除机器人"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("从圈子里移除对话"),
        "removeContact": MessageLookupByLibrary.simpleMessage("删除联系人"),
        "reply": MessageLookupByLibrary.simpleMessage("回复"),
        "report": MessageLookupByLibrary.simpleMessage("举报"),
        "reportWarning": MessageLookupByLibrary.simpleMessage("确定要举报这个联系人？"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "警告：此账号被大量用户举报，请谨防网络诈骗，注意个人财产安全"),
        "search": MessageLookupByLibrary.simpleMessage("搜索"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage("找不到联系人或消息。"),
        "searchMessageHistory": MessageLookupByLibrary.simpleMessage("搜索聊天记录"),
        "searchRelatedMessage": m20,
        "searchUser": MessageLookupByLibrary.simpleMessage("搜索用户"),
        "searchUserHint": MessageLookupByLibrary.simpleMessage("Mixin ID 或手机号"),
        "send": MessageLookupByLibrary.simpleMessage("发送"),
        "sendArchived": MessageLookupByLibrary.simpleMessage("打包成 zip 发送"),
        "sendQuick": MessageLookupByLibrary.simpleMessage("快速发送"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("发送原始文件"),
        "sendWithoutSound": MessageLookupByLibrary.simpleMessage("静音发送"),
        "sentYouAMessage": MessageLookupByLibrary.simpleMessage("发来一条信息"),
        "settingTheme": MessageLookupByLibrary.simpleMessage("主题"),
        "settingThemeAuto": MessageLookupByLibrary.simpleMessage("跟随系统"),
        "settingThemeLight": MessageLookupByLibrary.simpleMessage("浅色"),
        "settingThemeNight": MessageLookupByLibrary.simpleMessage("暗黑"),
        "shareContact": MessageLookupByLibrary.simpleMessage("发送名片"),
        "sharedApps": MessageLookupByLibrary.simpleMessage("分享的应用"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("媒体内容"),
        "show": MessageLookupByLibrary.simpleMessage("显示"),
        "signOut": MessageLookupByLibrary.simpleMessage("登出"),
        "sticker": MessageLookupByLibrary.simpleMessage("贴纸"),
        "storageAutoDownloadDescription":
            MessageLookupByLibrary.simpleMessage("更改媒体的自动下载设置。"),
        "storageUsage": MessageLookupByLibrary.simpleMessage("储存空间"),
        "strangerFromMessage":
            MessageLookupByLibrary.simpleMessage("他/她不是你的联系人"),
        "strangers": MessageLookupByLibrary.simpleMessage("陌生人"),
        "successful": MessageLookupByLibrary.simpleMessage("成功"),
        "termsService": MessageLookupByLibrary.simpleMessage("服务条款"),
        "text": MessageLookupByLibrary.simpleMessage("文字"),
        "time": MessageLookupByLibrary.simpleMessage("时间"),
        "to": MessageLookupByLibrary.simpleMessage("至"),
        "today": MessageLookupByLibrary.simpleMessage("今天"),
        "transactions": MessageLookupByLibrary.simpleMessage("转账记录"),
        "transactionsId": MessageLookupByLibrary.simpleMessage("交易编号"),
        "transfer": MessageLookupByLibrary.simpleMessage("转账"),
        "unMute": MessageLookupByLibrary.simpleMessage("取消静音"),
        "unPin": MessageLookupByLibrary.simpleMessage("取消置顶"),
        "unblock": MessageLookupByLibrary.simpleMessage("解除屏蔽"),
        "unpinAllMessages": MessageLookupByLibrary.simpleMessage("取消所有置顶"),
        "unpinAllMessagesDescription":
            MessageLookupByLibrary.simpleMessage("确认取消所有置顶吗？"),
        "unread": MessageLookupByLibrary.simpleMessage("未读消息"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("找不到这个用户"),
        "video": MessageLookupByLibrary.simpleMessage("视频"),
        "videoCall": MessageLookupByLibrary.simpleMessage("语音电话"),
        "videos": MessageLookupByLibrary.simpleMessage("视频"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("正在等待这个消息。"),
        "walletTransactionCurrentValue": m21,
        "walletTransactionThatTimeNoValue":
            MessageLookupByLibrary.simpleMessage("当时价值 暂无"),
        "walletTransactionThatTimeValue": m22,
        "webView2RuntimeInstallDescription":
            MessageLookupByLibrary.simpleMessage(
                "该设备暂未安装 WebView2 组件，请先下载并安装 WebView2 Runtime。"),
        "webViewRuntimeNotAvailable":
            MessageLookupByLibrary.simpleMessage("WebView2 组件不可用"),
        "you": MessageLookupByLibrary.simpleMessage("你"),
        "youStart": MessageLookupByLibrary.simpleMessage("您")
      };
}
