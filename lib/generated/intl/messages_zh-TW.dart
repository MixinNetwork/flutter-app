// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_TW locale. All the
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
  String get localeName => 'zh_TW';

  static String m0(arg0) => "${arg0}更改了限時消息設置。";

  static String m1(arg0) => "等待 ${arg0} 上線並建立加密會話。";

  static String m2(count, arg0) =>
      "${Intl.plural(count, one: '刪除 ${arg0} 條消息？', other: '刪除 ${arg0} 條消息？')}";

  static String m3(arg0, arg1) => "${arg0}添加了${arg1}";

  static String m4(arg0) => "${arg0}離開了群組";

  static String m5(arg0) => "${arg0}通過邀請鏈接加入了群組";

  static String m6(arg0, arg1) => "${arg0}移除了${arg1}";

  static String m7(arg0, arg1) => "${arg0}置頂${arg1}";

  static String m8(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} 對話', other: '${arg0} 對話')}";

  static String m9(arg0) => "${arg0}的圈子";

  static String m10(arg0) => "Mixin ID：${arg0}";

  static String m11(arg0) => "刪除聊天：${arg0}";

  static String m12(arg0) => "${arg0}創建了此群組";

  static String m13(arg0) => "要刪除 ${arg0} 個圈子嗎？";

  static String m14(arg0) => "${arg0}停用限時消息";

  static String m16(arg0) => "錯誤 20124：交易費用不足。請確保您的錢包有 ${arg0} 作為費用";

  static String m17(arg0, arg1) => "錯誤 30102：地址格式無效。請輸入正確的 ${arg0} ${arg1} 地址！";

  static String m18(arg0) => "錯誤 10006：請更新 Mixin(${arg0}) 以繼續使用該服務。";

  static String m19(count, arg0) =>
      "${Intl.plural(count, one: '錯誤 20119：PIN 不正確。您仍有 ${arg0} 次機會。請等待 24 小時後再試。', other: '錯誤 20119：PIN 不正確。您仍有 ${arg0} 次機會。請等待 24 小時後再試。')}";

  static String m20(arg0) => "服務器正在維護：${arg0}";

  static String m21(arg0) => "錯誤：${arg0}";

  static String m22(arg0) => "錯誤：${arg0}";

  static String m23(arg0) => "消息 ${arg0}";

  static String m24(arg0) => "移除 ${arg0}";

  static String m25(count) =>
      "${Intl.plural(count, one: '%d 小時', other: '%d 小時')}";

  static String m26(arg0) => "${arg0} 加入";

  static String m27(arg0) => "您的帳號將於 ${arg0} 被刪除，如果您繼續登錄，刪除帳號的請求將被取消。";

  static String m28(arg0) => "我們將向您的電話號碼 ${arg0} 發送一個 4 位代碼，請在下一個屏幕中輸入該代碼。";

  static String m29(arg0) => "請輸入發送至以下號碼的 4 位驗證碼：${arg0}";

  static String m30(arg0) => "我的 Mixin ID：${arg0}";

  static String m31(arg0, arg1) =>
      "Mixin Messenger ${arg0} 現已推出，您擁有 ${arg1}。你想現在下載嗎？";

  static String m32(arg0) => "${arg0}現在是管理員";

  static String m33(arg0) => "${arg0} 參與者";

  static String m34(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} 條置頂消息', other: '${arg0} 條置頂消息')}";

  static String m35(arg0) => "在 ${arg0} 秒內重新發送代碼";

  static String m36(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} 條相關消息', other: '${arg0} 條相關消息')}";

  static String m37(arg0, arg1) => "${arg0}將消息消失時間設置為${arg1}";

  static String m38(arg0) => "無法打開文件：${arg0}";

  static String m39(count) => "${Intl.plural(count, one: '天', other: '天')}";

  static String m40(count) => "${Intl.plural(count, one: '小時', other: '小時')}";

  static String m41(count) => "${Intl.plural(count, one: '分鐘', other: '分鐘')}";

  static String m42(count) => "${Intl.plural(count, one: '第二', other: '秒')}";

  static String m43(count) => "${Intl.plural(count, one: '星期', other: '週')}";

  static String m44(arg0) => "現在價值 ${arg0}";

  static String m45(arg0) => "當時價值 ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("一個消息"),
        "about": MessageLookupByLibrary.simpleMessage("關於"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("拒絕訪問"),
        "add": MessageLookupByLibrary.simpleMessage("添加"),
        "addBotWithPlus": MessageLookupByLibrary.simpleMessage("+ 添加機器人"),
        "addContact": MessageLookupByLibrary.simpleMessage("增加聯繫人"),
        "addContactWithPlus": MessageLookupByLibrary.simpleMessage("+ 添加聯繫人"),
        "addFile": MessageLookupByLibrary.simpleMessage("添加文件"),
        "addGroupDescription": MessageLookupByLibrary.simpleMessage("添加群組描述"),
        "addParticipants": MessageLookupByLibrary.simpleMessage("添加參與者"),
        "addPeopleSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID 或電話號碼"),
        "addSticker": MessageLookupByLibrary.simpleMessage("添加貼紙"),
        "addStickerFailed": MessageLookupByLibrary.simpleMessage("添加貼紙失敗"),
        "addStickers": MessageLookupByLibrary.simpleMessage("添加貼紙"),
        "added": MessageLookupByLibrary.simpleMessage("添加"),
        "admin": MessageLookupByLibrary.simpleMessage("管理員"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("分享了一個聯繫人"),
        "allChats": MessageLookupByLibrary.simpleMessage("聊天"),
        "appCardShareDisallow":
            MessageLookupByLibrary.simpleMessage("禁止共享此 URL"),
        "appearance": MessageLookupByLibrary.simpleMessage("外觀"),
        "archivedFolder": MessageLookupByLibrary.simpleMessage("存檔文件夾"),
        "assetType": MessageLookupByLibrary.simpleMessage("資產類型"),
        "audio": MessageLookupByLibrary.simpleMessage("語音"),
        "audios": MessageLookupByLibrary.simpleMessage("音頻"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("自動備份"),
        "avatar": MessageLookupByLibrary.simpleMessage("阿凡達"),
        "backup": MessageLookupByLibrary.simpleMessage("備份"),
        "biography": MessageLookupByLibrary.simpleMessage("傳"),
        "block": MessageLookupByLibrary.simpleMessage("屏蔽用戶"),
        "bots": MessageLookupByLibrary.simpleMessage("機器人"),
        "canNotRecognizeQrCode":
            MessageLookupByLibrary.simpleMessage("無法識別二維碼"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "card": MessageLookupByLibrary.simpleMessage("卡片"),
        "change": MessageLookupByLibrary.simpleMessage("改變"),
        "changedDisappearingMessageSettings": m0,
        "chatBackup": MessageLookupByLibrary.simpleMessage("聊天備份"),
        "chatBotReceptionTitle":
            MessageLookupByLibrary.simpleMessage("點擊按鈕與機器人交互"),
        "chatDecryptionFailedHint": m1,
        "chatDeleteMessage": m2,
        "chatGroupAdd": m3,
        "chatGroupExit": m4,
        "chatGroupJoin": m5,
        "chatGroupRemove": m6,
        "chatHintE2e": MessageLookupByLibrary.simpleMessage("端到端加密"),
        "chatNotSupportUriOnPhone":
            MessageLookupByLibrary.simpleMessage("不支持此類網址，請在手機上查看。"),
        "chatNotSupportUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
        "chatNotSupportViewOnPhone":
            MessageLookupByLibrary.simpleMessage("不支持此類消息，請在手機上查看。"),
        "chatPinMessage": m7,
        "checkNewVersion": MessageLookupByLibrary.simpleMessage("檢查新版本"),
        "choose": MessageLookupByLibrary.simpleMessage("選擇"),
        "circleSubtitle": m8,
        "circleTitle": m9,
        "circles": MessageLookupByLibrary.simpleMessage("圈子"),
        "clear": MessageLookupByLibrary.simpleMessage("清除"),
        "clearChat": MessageLookupByLibrary.simpleMessage("清除聊天記錄"),
        "clickToReloadQrcode":
            MessageLookupByLibrary.simpleMessage("點擊重新加載二維碼"),
        "close": MessageLookupByLibrary.simpleMessage("關"),
        "closeWindow": MessageLookupByLibrary.simpleMessage("關閉窗口"),
        "collapse": MessageLookupByLibrary.simpleMessage("坍塌"),
        "combineAndForward": MessageLookupByLibrary.simpleMessage("合併轉發"),
        "confirm": MessageLookupByLibrary.simpleMessage("確認"),
        "contact": MessageLookupByLibrary.simpleMessage("聯繫人"),
        "contactMixinId": m10,
        "contactMuteTitle": MessageLookupByLibrary.simpleMessage("靜音通知…"),
        "contacts": MessageLookupByLibrary.simpleMessage("聯繫人"),
        "contentTooLong": MessageLookupByLibrary.simpleMessage("內容太長"),
        "contentVoice": MessageLookupByLibrary.simpleMessage("[語音通話]"),
        "continueText": MessageLookupByLibrary.simpleMessage("繼續"),
        "conversation": MessageLookupByLibrary.simpleMessage("對話"),
        "conversationDeleteTitle": m11,
        "copy": MessageLookupByLibrary.simpleMessage("複製"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("複製邀請鏈接"),
        "create": MessageLookupByLibrary.simpleMessage("創建"),
        "createCircle": MessageLookupByLibrary.simpleMessage("新圈子"),
        "createConversation": MessageLookupByLibrary.simpleMessage("新對話"),
        "createGroup": MessageLookupByLibrary.simpleMessage("新集團"),
        "createdThisGroup": m12,
        "customTime": MessageLookupByLibrary.simpleMessage("自定義時間"),
        "dark": MessageLookupByLibrary.simpleMessage("深色"),
        "dataAndStorageUsage": MessageLookupByLibrary.simpleMessage("數據與存儲空間"),
        "dataError": MessageLookupByLibrary.simpleMessage("數據錯誤"),
        "dataLoading": MessageLookupByLibrary.simpleMessage("數據加載中，請稍候..."),
        "delete": MessageLookupByLibrary.simpleMessage("刪除"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("刪除聊天"),
        "deleteChatDescription": MessageLookupByLibrary.simpleMessage(
            "刪除聊天只會從該設備中刪除消息。它們不會從其他設備中刪除。"),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("刪除圈子"),
        "deleteForEveryone": MessageLookupByLibrary.simpleMessage("撤回"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("刪除"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("刪除組"),
        "deleteTheCircle": m13,
        "developer": MessageLookupByLibrary.simpleMessage("開發者"),
        "disableDisappearingMessage": m14,
        "disappearingMessage": MessageLookupByLibrary.simpleMessage("限時消息"),
        "disappearingMessageHint": MessageLookupByLibrary.simpleMessage(
            "啟用後，在此聊天中發送和接收的新消息將在看到後消失，請閱讀文檔以**瞭解更多**。"),
        "dismissAsAdmin": MessageLookupByLibrary.simpleMessage("撤銷管理員身份"),
        "done": MessageLookupByLibrary.simpleMessage("完畢"),
        "download": MessageLookupByLibrary.simpleMessage("下載"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("下載鏈接："),
        "dragAndDropFileHere": MessageLookupByLibrary.simpleMessage("將文件拖放到此處"),
        "durationIsTooShort": MessageLookupByLibrary.simpleMessage("持續時間太短"),
        "editCircleName": MessageLookupByLibrary.simpleMessage("編輯圈子名稱"),
        "editGroupDescription": MessageLookupByLibrary.simpleMessage("編輯組描述"),
        "editGroupName": MessageLookupByLibrary.simpleMessage("編輯組名"),
        "editImageClearWarning":
            MessageLookupByLibrary.simpleMessage("所有更改都將丟失。你確定要離開？"),
        "editName": MessageLookupByLibrary.simpleMessage("編輯名稱"),
        "editProfile": MessageLookupByLibrary.simpleMessage("編輯個人資料"),
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("輸入你的電話號碼"),
        "errorAddressExists":
            MessageLookupByLibrary.simpleMessage("地址不存在，請確保地址添加成功"),
        "errorAddressNotSync":
            MessageLookupByLibrary.simpleMessage("地址刷新失敗，請重試"),
        "errorAssetExists": MessageLookupByLibrary.simpleMessage("資產不存在"),
        "errorAuthentication":
            MessageLookupByLibrary.simpleMessage("錯誤 401：登錄以繼續"),
        "errorBadData":
            MessageLookupByLibrary.simpleMessage("ERROR 10002：請求數據包含無效字段"),
        "errorBlockchain":
            MessageLookupByLibrary.simpleMessage("ERROR 30100：區塊鏈不同步，請稍後再試。"),
        "errorConnectionTimeout":
            MessageLookupByLibrary.simpleMessage("網絡連接超時，請重試"),
        "errorFullGroup":
            MessageLookupByLibrary.simpleMessage("ERROR 20116：群聊已滿。"),
        "errorInsufficientBalance":
            MessageLookupByLibrary.simpleMessage("錯誤 20117：餘額不足"),
        "errorInsufficientTransactionFeeWithAmount": m16,
        "errorInvalidAddress": m17,
        "errorInvalidAddressPlain":
            MessageLookupByLibrary.simpleMessage("錯誤 30102：地址格式無效。"),
        "errorInvalidCodeTooFrequent": MessageLookupByLibrary.simpleMessage(
            "ERROR 20129：發送驗證碼過於頻繁，請稍後再試。"),
        "errorInvalidEmergencyContact":
            MessageLookupByLibrary.simpleMessage("錯誤 20130：緊急聯繫人無效"),
        "errorInvalidPinFormat":
            MessageLookupByLibrary.simpleMessage("錯誤 20118：PIN 格式無效。"),
        "errorNetworkTaskFailed":
            MessageLookupByLibrary.simpleMessage("網絡連接失敗。檢查或切換您的網絡，然後重試"),
        "errorNotFound": MessageLookupByLibrary.simpleMessage("未找到錯誤 404"),
        "errorNotSupportedAudioFormat":
            MessageLookupByLibrary.simpleMessage("不支持的音頻格式，請用其他應用打開。"),
        "errorNumberReachedLimit":
            MessageLookupByLibrary.simpleMessage("錯誤 20132：數量已達到限制。"),
        "errorOldVersion": m18,
        "errorOpenLocation": MessageLookupByLibrary.simpleMessage("找不到地圖應用"),
        "errorPermission": MessageLookupByLibrary.simpleMessage("請打開必要的權限"),
        "errorPhoneInvalidFormat":
            MessageLookupByLibrary.simpleMessage("錯誤 20110：電話號碼無效"),
        "errorPhoneSmsDelivery":
            MessageLookupByLibrary.simpleMessage("ERROR 10003：發送短信失敗"),
        "errorPhoneVerificationCodeExpired":
            MessageLookupByLibrary.simpleMessage("ERROR 20114：手機驗證碼過期"),
        "errorPhoneVerificationCodeInvalid":
            MessageLookupByLibrary.simpleMessage("ERROR 20113：手機驗證碼無效"),
        "errorPinCheckTooManyRequest":
            MessageLookupByLibrary.simpleMessage("您已嘗試超過 5 次，請等待至少 24 小時再試。"),
        "errorPinIncorrect":
            MessageLookupByLibrary.simpleMessage("錯誤 20119：PIN 不正確"),
        "errorPinIncorrectWithTimes": m19,
        "errorRecaptchaIsInvalid":
            MessageLookupByLibrary.simpleMessage("ERROR 10004：Recaptcha 無效"),
        "errorServer5xxCode": m20,
        "errorTooManyRequest":
            MessageLookupByLibrary.simpleMessage("錯誤 429：超出速率限制"),
        "errorTooManyStickers":
            MessageLookupByLibrary.simpleMessage("錯誤 20126：貼紙太多"),
        "errorTooSmallTransferAmount":
            MessageLookupByLibrary.simpleMessage("ERROR 20120：轉賬金額太小"),
        "errorTooSmallWithdrawAmount":
            MessageLookupByLibrary.simpleMessage("ERROR 20127：提款金額太小"),
        "errorTranscriptForward":
            MessageLookupByLibrary.simpleMessage("下載後請轉發所有附件"),
        "errorUnableToOpenMedia":
            MessageLookupByLibrary.simpleMessage("找不到能夠打開此媒體的應用。"),
        "errorUnknownWithCode": m21,
        "errorUnknownWithMessage": m22,
        "errorUsedPhone":
            MessageLookupByLibrary.simpleMessage("錯誤 20122：此電話號碼已與另一個帳戶相關聯。"),
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("無效的用戶 ID"),
        "errorWithdrawalMemoFormatIncorrect":
            MessageLookupByLibrary.simpleMessage("錯誤 20131：提款備註格式不正確。"),
        "exit": MessageLookupByLibrary.simpleMessage("退出"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("退出群組"),
        "failed": MessageLookupByLibrary.simpleMessage("失敗的"),
        "file": MessageLookupByLibrary.simpleMessage("文件"),
        "fileChooserError": MessageLookupByLibrary.simpleMessage("文件選擇器錯誤"),
        "fileDoesNotExist": MessageLookupByLibrary.simpleMessage("文件不存在"),
        "fileError": MessageLookupByLibrary.simpleMessage("文件錯誤"),
        "files": MessageLookupByLibrary.simpleMessage("文件"),
        "followSystem": MessageLookupByLibrary.simpleMessage("跟隨系統"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("在 Facebook 上關注我們"),
        "followUsOnTwitter": MessageLookupByLibrary.simpleMessage("在推特上關注我們"),
        "formatNotSupported": MessageLookupByLibrary.simpleMessage("不支持格式"),
        "forward": MessageLookupByLibrary.simpleMessage("轉發"),
        "from": MessageLookupByLibrary.simpleMessage("從"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("從："),
        "groupCantSend":
            MessageLookupByLibrary.simpleMessage("由於您不再是參與者，因此您無法向此群組發送消息。"),
        "groupName": MessageLookupByLibrary.simpleMessage("群組名字"),
        "groupParticipants": MessageLookupByLibrary.simpleMessage("參與者"),
        "groupPopMenuMessage": m23,
        "groupPopMenuRemove": m24,
        "groups": MessageLookupByLibrary.simpleMessage("團體"),
        "groupsInCommon": MessageLookupByLibrary.simpleMessage("共同的群組"),
        "help": MessageLookupByLibrary.simpleMessage("幫助"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("幫助中心"),
        "hideMixin": MessageLookupByLibrary.simpleMessage("隱藏混音"),
        "hour": m25,
        "ignoreThisVersion": MessageLookupByLibrary.simpleMessage("忽略新版本"),
        "image": MessageLookupByLibrary.simpleMessage("圖片"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("包含文件"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("包括視頻"),
        "initializing": MessageLookupByLibrary.simpleMessage("正在初始化…"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "任何擁有 Mixin 的人都可以點擊此鏈接加入此群組。僅與您信任的人分享。"),
        "inviteToGroupViaLink":
            MessageLookupByLibrary.simpleMessage("通過鏈接邀請加入群組"),
        "joinGroupWithPlus": MessageLookupByLibrary.simpleMessage("+ 加入群組"),
        "joinedIn": m26,
        "landingDeleteContent": m27,
        "landingInvitationDialogContent": m28,
        "landingValidationTitle": m29,
        "learnMore": MessageLookupByLibrary.simpleMessage("瞭解更多"),
        "less": MessageLookupByLibrary.simpleMessage("較少的"),
        "light": MessageLookupByLibrary.simpleMessage("淺色"),
        "live": MessageLookupByLibrary.simpleMessage("直播"),
        "loading": MessageLookupByLibrary.simpleMessage("正在加載..."),
        "loadingTime": MessageLookupByLibrary.simpleMessage("系統時間異常，請修正後再繼續使用"),
        "locateToChat": MessageLookupByLibrary.simpleMessage("定位聊天"),
        "location": MessageLookupByLibrary.simpleMessage("地點"),
        "logIn": MessageLookupByLibrary.simpleMessage("登錄"),
        "loginAndAbortAccountDeletion":
            MessageLookupByLibrary.simpleMessage("繼續登錄併中止帳戶刪除"),
        "loginByQrcode":
            MessageLookupByLibrary.simpleMessage("二維碼登錄 Mixin Messenger"),
        "loginByQrcodeTips": MessageLookupByLibrary.simpleMessage(
            "在手機上打開 Mixin Messenger，掃描屏幕上的二維碼並確認登錄。"),
        "makeGroupAdmin": MessageLookupByLibrary.simpleMessage("設定為群組管理員"),
        "media": MessageLookupByLibrary.simpleMessage("媒體"),
        "memo": MessageLookupByLibrary.simpleMessage("備註"),
        "messageE2ee":
            MessageLookupByLibrary.simpleMessage("此對話的消息是端到端加密的，點按以獲取更多信息。"),
        "messageNotFound": MessageLookupByLibrary.simpleMessage("未找到信息"),
        "messageNotSupport":
            MessageLookupByLibrary.simpleMessage("不支持此類消息，請將 Mixin 升級到最新版本。"),
        "messagePreview": MessageLookupByLibrary.simpleMessage("消息預覽"),
        "messagePreviewDescription":
            MessageLookupByLibrary.simpleMessage("在新消息通知中預覽消息文本。"),
        "messages": MessageLookupByLibrary.simpleMessage("消息"),
        "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger 桌面版"),
        "more": MessageLookupByLibrary.simpleMessage("更多"),
        "mute": MessageLookupByLibrary.simpleMessage("沉默的"),
        "muted": MessageLookupByLibrary.simpleMessage("已靜音"),
        "myMixinId": m30,
        "myStickers": MessageLookupByLibrary.simpleMessage("我的貼紙"),
        "na": MessageLookupByLibrary.simpleMessage("暫無價格"),
        "name": MessageLookupByLibrary.simpleMessage("姓名"),
        "networkError": MessageLookupByLibrary.simpleMessage("網絡錯誤"),
        "newVersionAvailable": MessageLookupByLibrary.simpleMessage("新版本可用"),
        "newVersionDescription": m31,
        "next": MessageLookupByLibrary.simpleMessage("下一步"),
        "nextConversation": MessageLookupByLibrary.simpleMessage("下一次對話"),
        "noAudio": MessageLookupByLibrary.simpleMessage("沒有音頻"),
        "noCamera": MessageLookupByLibrary.simpleMessage("沒有相機"),
        "noData": MessageLookupByLibrary.simpleMessage("沒有數據"),
        "noFiles": MessageLookupByLibrary.simpleMessage("沒有文件"),
        "noLinks": MessageLookupByLibrary.simpleMessage("沒有鏈接"),
        "noMedia": MessageLookupByLibrary.simpleMessage("沒有媒體"),
        "noNetworkConnection": MessageLookupByLibrary.simpleMessage("無網絡連接"),
        "noPosts": MessageLookupByLibrary.simpleMessage("沒有帖子"),
        "noResults": MessageLookupByLibrary.simpleMessage("沒有結果"),
        "notFound": MessageLookupByLibrary.simpleMessage("未找到"),
        "notificationContent":
            MessageLookupByLibrary.simpleMessage("不要錯過朋友的消息。"),
        "notificationPermissionManually":
            MessageLookupByLibrary.simpleMessage("不允許通知，請前往通知設置開啟。"),
        "notifications": MessageLookupByLibrary.simpleMessage("通知"),
        "nowAnAddmin": m32,
        "oneByOneForward": MessageLookupByLibrary.simpleMessage("逐條轉發"),
        "oneHour": MessageLookupByLibrary.simpleMessage("1 小時"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1 週"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1 年"),
        "openHomePage": MessageLookupByLibrary.simpleMessage("打開主頁"),
        "openLogDirectory": MessageLookupByLibrary.simpleMessage("打開日誌目錄"),
        "originalImage": MessageLookupByLibrary.simpleMessage("原來的"),
        "owner": MessageLookupByLibrary.simpleMessage("所有者"),
        "participantsCount": m33,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("電話號碼"),
        "photos": MessageLookupByLibrary.simpleMessage("相片"),
        "pickAConversation":
            MessageLookupByLibrary.simpleMessage("選擇一個對話並開始發送消息"),
        "pinTitle": MessageLookupByLibrary.simpleMessage("置頂"),
        "pinnedMessageTitle": m34,
        "post": MessageLookupByLibrary.simpleMessage("文章"),
        "preferences": MessageLookupByLibrary.simpleMessage("喜好"),
        "previousConversation": MessageLookupByLibrary.simpleMessage("以前的對話"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("隱私政策"),
        "quickSearch": MessageLookupByLibrary.simpleMessage("快速搜索"),
        "quitMixin": MessageLookupByLibrary.simpleMessage("退出 Mixin"),
        "recaptchaTimeout": MessageLookupByLibrary.simpleMessage("驗證碼超時"),
        "receiver": MessageLookupByLibrary.simpleMessage("至"),
        "recentChats": MessageLookupByLibrary.simpleMessage("聊天室"),
        "reedit": MessageLookupByLibrary.simpleMessage("重新編輯"),
        "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
        "removeBot": MessageLookupByLibrary.simpleMessage("刪除機器人"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("從圈子中刪除聊天"),
        "removeContact": MessageLookupByLibrary.simpleMessage("刪除聯繫人"),
        "removeStickers": MessageLookupByLibrary.simpleMessage("刪除貼紙"),
        "reply": MessageLookupByLibrary.simpleMessage("回復"),
        "report": MessageLookupByLibrary.simpleMessage("舉報"),
        "reportAndBlock": MessageLookupByLibrary.simpleMessage("舉報並屏蔽？"),
        "resendCode": MessageLookupByLibrary.simpleMessage("重新發送驗證碼"),
        "resendCodeIn": m35,
        "reset": MessageLookupByLibrary.simpleMessage("重置"),
        "resetLink": MessageLookupByLibrary.simpleMessage("重置鏈接"),
        "retryUploadFailed": MessageLookupByLibrary.simpleMessage("重試上傳失敗。"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saveAs": MessageLookupByLibrary.simpleMessage("另存為"),
        "saveToCameraRoll": MessageLookupByLibrary.simpleMessage("保存到相機膠卷"),
        "sayHi": MessageLookupByLibrary.simpleMessage("打招呼"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "警告：許多用戶將此帳戶報告為騙局。請小心，尤其是當它向您要錢時"),
        "search": MessageLookupByLibrary.simpleMessage("搜索"),
        "searchContact": MessageLookupByLibrary.simpleMessage("搜索聯繫人"),
        "searchConversation": MessageLookupByLibrary.simpleMessage("搜索對話"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage("未找到任何聊天、聯繫人或消息。"),
        "searchRelatedMessage": m36,
        "secretUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "send": MessageLookupByLibrary.simpleMessage("發送"),
        "sendArchived":
            MessageLookupByLibrary.simpleMessage("將所有文件歸檔在一個 zip 文件中"),
        "sendQuickly": MessageLookupByLibrary.simpleMessage("快速發送"),
        "sendWithoutCompression": MessageLookupByLibrary.simpleMessage("不壓縮發送"),
        "sendWithoutSound": MessageLookupByLibrary.simpleMessage("無聲發送"),
        "set": MessageLookupByLibrary.simpleMessage("設置"),
        "setDisappearingMessageTimeTo": m37,
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID，名稱"),
        "settingBackupTips": MessageLookupByLibrary.simpleMessage(
            "將您的聊天記錄備份到 iCloud。如果您丟失了 iPhone 或更換了新 iPhone，您可以在重新安裝 Mixin Messenger 時恢復您的聊天記錄。您備份的消息在 iCloud 中不受 Mixin Messenger 端到端加密的保護。"),
        "share": MessageLookupByLibrary.simpleMessage("分享"),
        "shareApps": MessageLookupByLibrary.simpleMessage("共享應用程序"),
        "shareContact": MessageLookupByLibrary.simpleMessage("分享聯繫方式"),
        "shareError": MessageLookupByLibrary.simpleMessage("共享錯誤。"),
        "shareLink": MessageLookupByLibrary.simpleMessage("分享鏈接"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("共享媒體"),
        "show": MessageLookupByLibrary.simpleMessage("顯示"),
        "showAvatar": MessageLookupByLibrary.simpleMessage("顯示頭像"),
        "showMixin": MessageLookupByLibrary.simpleMessage("顯示混音"),
        "signIn": MessageLookupByLibrary.simpleMessage("登入"),
        "signOut": MessageLookupByLibrary.simpleMessage("登出"),
        "signWithPhoneNumber": MessageLookupByLibrary.simpleMessage("使用電話號碼登錄"),
        "signWithQrcode": MessageLookupByLibrary.simpleMessage("使用二維碼登錄"),
        "sticker": MessageLookupByLibrary.simpleMessage("貼紙"),
        "stickerAlbumDetail": MessageLookupByLibrary.simpleMessage("貼紙專輯詳情"),
        "stickerStore": MessageLookupByLibrary.simpleMessage("貼紙店"),
        "storageAutoDownloadDescription":
            MessageLookupByLibrary.simpleMessage("更改媒體的自動下載設置。"),
        "storageUsage": MessageLookupByLibrary.simpleMessage("儲存空間"),
        "strangerHint": MessageLookupByLibrary.simpleMessage("此發件人不在您的通訊錄中"),
        "strangers": MessageLookupByLibrary.simpleMessage("陌生人"),
        "successful": MessageLookupByLibrary.simpleMessage("成功的"),
        "termsOfService": MessageLookupByLibrary.simpleMessage("服務條款"),
        "text": MessageLookupByLibrary.simpleMessage("文本"),
        "theme": MessageLookupByLibrary.simpleMessage("主題"),
        "thisMessageWasDeleted": MessageLookupByLibrary.simpleMessage("此消息已刪除"),
        "time": MessageLookupByLibrary.simpleMessage("時間"),
        "today": MessageLookupByLibrary.simpleMessage("今天"),
        "toggleChatInfo": MessageLookupByLibrary.simpleMessage("切換聊天信息"),
        "transactionId": MessageLookupByLibrary.simpleMessage("交易編號"),
        "transactions": MessageLookupByLibrary.simpleMessage("轉賬記錄"),
        "transcript": MessageLookupByLibrary.simpleMessage("聊天記錄"),
        "transfer": MessageLookupByLibrary.simpleMessage("轉賬"),
        "turnOnNotifications": MessageLookupByLibrary.simpleMessage("打開通知"),
        "typeMessage": MessageLookupByLibrary.simpleMessage("輸入消息"),
        "unableToOpenFile": m38,
        "unblock": MessageLookupByLibrary.simpleMessage("解除屏蔽"),
        "unitDay": m39,
        "unitHour": m40,
        "unitMinute": m41,
        "unitSecond": m42,
        "unitWeek": m43,
        "unmute": MessageLookupByLibrary.simpleMessage("取消靜音"),
        "unpin": MessageLookupByLibrary.simpleMessage("取消置頂"),
        "unpinAllMessages": MessageLookupByLibrary.simpleMessage("取消置頂所有消息"),
        "unpinAllMessagesConfirmation":
            MessageLookupByLibrary.simpleMessage("您確定要取消置頂所有消息嗎？"),
        "unreadMessages": MessageLookupByLibrary.simpleMessage("未讀消息"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("未找到用戶"),
        "valueNow": m44,
        "valueThen": m45,
        "video": MessageLookupByLibrary.simpleMessage("視頻"),
        "videos": MessageLookupByLibrary.simpleMessage("視頻"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("等待這個消息。"),
        "webview2RuntimeInstallDescription":
            MessageLookupByLibrary.simpleMessage(
                "設備未安裝 WebView2 運行時組件。請先下載並安裝 WebView2 Runtime。"),
        "webviewRuntimeUnavailable":
            MessageLookupByLibrary.simpleMessage("WebView 運行時不可用"),
        "whatsYourName": MessageLookupByLibrary.simpleMessage("你叫什麼名字？"),
        "window": MessageLookupByLibrary.simpleMessage("窗戶"),
        "writeCircles": MessageLookupByLibrary.simpleMessage("管理圈子"),
        "you": MessageLookupByLibrary.simpleMessage("你"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("你刪除了這條消息")
      };
}
