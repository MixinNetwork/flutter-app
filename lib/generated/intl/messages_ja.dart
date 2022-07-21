// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
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
  String get localeName => 'ja';

  static String m0(arg0) => "表示されないメッセージ";

  static String m1(arg0) => "${arg0}が参加し暗号化セッションが開始するまで待機しています...";

  static String m2(count, arg0) =>
      "${Intl.plural(count, one: '${arg0}のメッセージを削除しますか？', other: '${arg0}のメッセージを削除しますか？')}";

  static String m3(arg0, arg1) => "${arg0}が${arg1}を追加しました";

  static String m4(arg0) => "退出";

  static String m5(arg0) => "${arg0}が招待リンクから参加しました";

  static String m6(arg0, arg1) => "${arg0}が${arg1}を退会させました";

  static String m7(arg0, arg1) => "${arg0}は${arg1}をピン留めしました";

  static String m8(count, arg0) =>
      "${Intl.plural(count, one: '${arg0}個', other: '${arg0}個')}";

  static String m9(arg0) => "${arg0}のリスト";

  static String m10(arg0) => "Mixin ID";

  static String m11(arg0) => "チャットを削除する：${arg0}";

  static String m12(arg0) => "${arg0}がグループを作成しました";

  static String m13(arg0) => "${arg0}のリストを削除しますか？";

  static String m14(arg0) => "${arg0}が表示されないメッセージを無効にしました";

  static String m16(arg0) => "トランザクション手数料が不足しています";

  static String m17(arg0, arg1) =>
      "エラー30102：無効なアドレス形式です。正しい${arg0} ${arg1} アドレスを入力してください。";

  static String m18(arg0) =>
      "エラー 10006：このサービスを引き続き使用するには、Mixin(${arg0})をアップデートしてください。";

  static String m19(count, arg0) =>
      "${Intl.plural(count, one: 'エラー 20119: PINコードが間違っています。あと${arg0}回入力可能です。24時間後に再試行してください。', other: 'エラー20119: PINコードが間違っています。あと${arg0}回入力可能です。24時間後に再試行してください。')}";

  static String m20(arg0) => "サーバーメンテナンス中: ${arg0}";

  static String m21(arg0) => "エラー: ${arg0}";

  static String m22(arg0) => "エラー: ${arg0}";

  static String m23(arg0) => "メッセージを送信";

  static String m24(arg0) => "グループから退会させる";

  static String m25(count) =>
      "${Intl.plural(count, one: '%d時間', other: '%d時間')}";

  static String m26(arg0) => "${arg0}からMixinを利用しています";

  static String m27(arg0) => "バージョンが古いです (${arg0}) 最新版Mixinにアップデートしてください";

  static String m28(arg0) => "4桁のコードを電話番号${arg0}に送信します、次の画面でコードを入力してください";

  static String m29(arg0) => "${arg0}に送信された4桁のコードを入力してください";

  static String m30(arg0) => "マイMixin ID:${arg0}";

  static String m31(arg0, arg1) => "Mixin${arg0}が利用可能です。今すぐアップデートしますか？";

  static String m32(arg0) => "${arg0}はサブリーダーです";

  static String m33(arg0) => "${arg0}人のメンバー";

  static String m34(count, arg0) =>
      "${Intl.plural(count, one: '${arg0}個のピン留めされたメッセージ', other: '${arg0}個のピン留めされたメッセージ')}";

  static String m35(arg0) => "${arg0}秒後にコードを再送";

  static String m36(count, arg0) =>
      "${Intl.plural(count, one: '${arg0}個の関連するメッセージ', other: '${arg0}個の関連するメッセージ')}";

  static String m37(arg0, arg1) => "1\$sは、消えるメッセージの有効時間を${arg0}に設定しました。";

  static String m38(arg0) => "ファイルを開くことができません: ${arg0}";

  static String m39(count) => "${Intl.plural(count, one: '日', other: '日間')}";

  static String m40(count) => "${Intl.plural(count, one: '時', other: '時間')}";

  static String m41(count) => "${Intl.plural(count, one: '分', other: '分間')}";

  static String m42(count) => "${Intl.plural(count, one: '秒', other: '秒間')}";

  static String m43(count) => "${Intl.plural(count, one: '週', other: '週間')}";

  static String m44(arg0) => "現在価格 ${arg0}";

  static String m45(arg0) => "当時の価格 ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("メッセージ"),
        "about": MessageLookupByLibrary.simpleMessage("Mixinについて"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("アクセスが拒否されました"),
        "add": MessageLookupByLibrary.simpleMessage("追加"),
        "addBotWithPlus": MessageLookupByLibrary.simpleMessage("Myミニアプリに追加"),
        "addContact": MessageLookupByLibrary.simpleMessage("友だちを追加"),
        "addContactWithPlus": MessageLookupByLibrary.simpleMessage("友だちを追加"),
        "addFile": MessageLookupByLibrary.simpleMessage("ファイルの追加"),
        "addGroupDescription":
            MessageLookupByLibrary.simpleMessage("グループアナウンス"),
        "addParticipants": MessageLookupByLibrary.simpleMessage("参加者"),
        "addPeopleSearchHint":
            MessageLookupByLibrary.simpleMessage("資産, 連絡先とメッセージ"),
        "addSticker": MessageLookupByLibrary.simpleMessage("スタンプを追加する"),
        "addStickerFailed": MessageLookupByLibrary.simpleMessage("失敗しました"),
        "addStickers": MessageLookupByLibrary.simpleMessage("スタンプを追加"),
        "added": MessageLookupByLibrary.simpleMessage("追加ずみ"),
        "admin": MessageLookupByLibrary.simpleMessage("サブリーダー"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("連絡先が届きました"),
        "allChats": MessageLookupByLibrary.simpleMessage("チャット"),
        "appCardShareDisallow": MessageLookupByLibrary.simpleMessage("共有"),
        "appearance": MessageLookupByLibrary.simpleMessage("言語とテーマ"),
        "archivedFolder": MessageLookupByLibrary.simpleMessage("アーカイブされたフォルダ"),
        "assetType": MessageLookupByLibrary.simpleMessage("資産タイプ"),
        "audio": MessageLookupByLibrary.simpleMessage("音声"),
        "audios": MessageLookupByLibrary.simpleMessage("音声メッセージ"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("チャット履歴のバックアップ"),
        "avatar": MessageLookupByLibrary.simpleMessage("アバター"),
        "biography": MessageLookupByLibrary.simpleMessage("経歴"),
        "block": MessageLookupByLibrary.simpleMessage("ブロック"),
        "bots": MessageLookupByLibrary.simpleMessage("ロボ"),
        "canNotRecognizeQrCode":
            MessageLookupByLibrary.simpleMessage("QRコードが見つかりません"),
        "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "card": MessageLookupByLibrary.simpleMessage("カード"),
        "change": MessageLookupByLibrary.simpleMessage("変更"),
        "changedDisappearingMessageSettings": m0,
        "chatBackup": MessageLookupByLibrary.simpleMessage("チャットのバックアップ"),
        "chatBotReceptionTitle":
            MessageLookupByLibrary.simpleMessage("ミニアプリを使用するためにボタンをタップしてください"),
        "chatDecryptionFailedHint": m1,
        "chatDeleteMessage": m2,
        "chatGroupAdd": m3,
        "chatGroupExit": m4,
        "chatGroupJoin": m5,
        "chatGroupRemove": m6,
        "chatHintE2e": MessageLookupByLibrary.simpleMessage("エンドツーエンド暗号化"),
        "chatNotSupportUriOnPhone": MessageLookupByLibrary.simpleMessage(
            "URLが読み込めません。お使いの携帯電話の設定をご確認ください。"),
        "chatNotSupportUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
        "chatNotSupportViewOnPhone": MessageLookupByLibrary.simpleMessage(
            "チャットが読み込めません。お使いの携帯電話の設定をご確認ください。"),
        "chatPinMessage": m7,
        "checkNewVersion": MessageLookupByLibrary.simpleMessage("最新版をチェック"),
        "choose": MessageLookupByLibrary.simpleMessage("選択"),
        "circleSubtitle": m8,
        "circleTitle": m9,
        "circles": MessageLookupByLibrary.simpleMessage("リスト"),
        "clear": MessageLookupByLibrary.simpleMessage("クリア"),
        "clearChat": MessageLookupByLibrary.simpleMessage("チャットをクリア"),
        "clickToReloadQrcode": MessageLookupByLibrary.simpleMessage("リロード"),
        "close": MessageLookupByLibrary.simpleMessage("閉じる"),
        "closeWindow": MessageLookupByLibrary.simpleMessage("Window"),
        "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
        "combineAndForward": MessageLookupByLibrary.simpleMessage("転送"),
        "confirm": MessageLookupByLibrary.simpleMessage("許可する"),
        "contact": MessageLookupByLibrary.simpleMessage("連絡先"),
        "contactMixinId": m10,
        "contactMuteTitle": MessageLookupByLibrary.simpleMessage("通知をミュート:"),
        "contacts": MessageLookupByLibrary.simpleMessage("連絡先"),
        "contentTooLong": MessageLookupByLibrary.simpleMessage("文字数を減らしてください"),
        "contentVoice": MessageLookupByLibrary.simpleMessage("[音声通話]"),
        "continueText": MessageLookupByLibrary.simpleMessage("続ける"),
        "conversation": MessageLookupByLibrary.simpleMessage("会話"),
        "conversationDeleteTitle": m11,
        "copy": MessageLookupByLibrary.simpleMessage("コピー"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("リンクをコピーする"),
        "create": MessageLookupByLibrary.simpleMessage("作成"),
        "createCircle": MessageLookupByLibrary.simpleMessage("新しいリスト"),
        "createConversation": MessageLookupByLibrary.simpleMessage("新しい会話"),
        "createGroup": MessageLookupByLibrary.simpleMessage("新しいグループ"),
        "createdThisGroup": m12,
        "customTime": MessageLookupByLibrary.simpleMessage("日時"),
        "dark": MessageLookupByLibrary.simpleMessage("夜間モード"),
        "dataAndStorageUsage": MessageLookupByLibrary.simpleMessage("ストレージ使用率"),
        "dataError": MessageLookupByLibrary.simpleMessage("データエラー"),
        "dataLoading": MessageLookupByLibrary.simpleMessage("ロード中..."),
        "delete": MessageLookupByLibrary.simpleMessage("削除"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("チャットを削除"),
        "deleteChatDescription": MessageLookupByLibrary.simpleMessage(
            "チャットを削除すると、この端末のみからメッセージが削除されます。他の端末からは削除されません。"),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("リストを削除"),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("全員のチャットから削除"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("あなたのチャットから削除"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("グループを削除"),
        "deleteTheCircle": m13,
        "developer": MessageLookupByLibrary.simpleMessage("開発者情報"),
        "disableDisappearingMessage": m14,
        "disappearingMessageHint": MessageLookupByLibrary.simpleMessage(
            "有効にすると、このチャットで送受信された新しいメッセージは、見た後に消えます。詳しくは、ドキュ**メントをお読みください**。"),
        "dismissAsAdmin": MessageLookupByLibrary.simpleMessage("サブリーダー権限を解除"),
        "done": MessageLookupByLibrary.simpleMessage("完了"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("ダウンロードリンク:"),
        "dragAndDropFileHere":
            MessageLookupByLibrary.simpleMessage("ファイルをドラッグ＆ドロップ"),
        "durationIsTooShort": MessageLookupByLibrary.simpleMessage("期間が短すぎます"),
        "editCircleName": MessageLookupByLibrary.simpleMessage("チャットグループ名を編集"),
        "editGroupDescription":
            MessageLookupByLibrary.simpleMessage("グループアナウンスを編集"),
        "editGroupName": MessageLookupByLibrary.simpleMessage("グループ名"),
        "editImageClearWarning":
            MessageLookupByLibrary.simpleMessage("すべての変更が失われます。本当に終了しますか？"),
        "editName": MessageLookupByLibrary.simpleMessage("名前を変更"),
        "editProfile": MessageLookupByLibrary.simpleMessage("プロフィールを編集"),
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("電話番号を入力して下さい"),
        "errorAddressExists": MessageLookupByLibrary.simpleMessage(
            "アドレスが存在しません。アドレスが正常に追加されていることを確認してください。"),
        "errorAddressNotSync": MessageLookupByLibrary.simpleMessage(
            "アドレスの更新に失敗しました。もう一度やり直してください。"),
        "errorAssetExists": MessageLookupByLibrary.simpleMessage("資産がありません"),
        "errorAuthentication":
            MessageLookupByLibrary.simpleMessage("エラー 401: サインインをして続ける"),
        "errorBadData":
            MessageLookupByLibrary.simpleMessage("エラー 10002: リクエストデータが無効です"),
        "errorBlockchain": MessageLookupByLibrary.simpleMessage(
            "エラー 30100:ブロックチェーンが同期できていません。後程もう一度お試し下さい。"),
        "errorConnectionTimeout":
            MessageLookupByLibrary.simpleMessage("ネットワーク接続がタイムアウトしました"),
        "errorFullGroup":
            MessageLookupByLibrary.simpleMessage("エラー 20116: グループチャットが満員です"),
        "errorInsufficientBalance":
            MessageLookupByLibrary.simpleMessage("エラー 20117: 残高が不足しています"),
        "errorInsufficientTransactionFeeWithAmount": m16,
        "errorInvalidAddress": m17,
        "errorInvalidAddressPlain":
            MessageLookupByLibrary.simpleMessage("エラー30102：無効なアドレス形式です。"),
        "errorInvalidCodeTooFrequent": MessageLookupByLibrary.simpleMessage(
            "エラー 20129：認証コードを送信する頻度が多すぎます。しばらくしてからもう一度お試しください。"),
        "errorInvalidEmergencyContact":
            MessageLookupByLibrary.simpleMessage("エラー 20130：緊急連絡先が無効です"),
        "errorInvalidPinFormat":
            MessageLookupByLibrary.simpleMessage("エラー 20118：無効なPINフォーマットです"),
        "errorNetworkTaskFailed": MessageLookupByLibrary.simpleMessage(
            "ネットワーク接続に失敗しました。ネットワーク接続状態を確認した後にもう一度試してください。"),
        "errorNotFound": MessageLookupByLibrary.simpleMessage("エラー 404：結果なし"),
        "errorNotSupportedAudioFormat": MessageLookupByLibrary.simpleMessage(
            "サポートされていないオーディオ形式です。他のアプリで開いてください。"),
        "errorNumberReachedLimit":
            MessageLookupByLibrary.simpleMessage("数が上限に達しました"),
        "errorOldVersion": m18,
        "errorOpenLocation":
            MessageLookupByLibrary.simpleMessage("地図アプリがありません"),
        "errorPermission":
            MessageLookupByLibrary.simpleMessage("必要な権限を開いてください"),
        "errorPhoneInvalidFormat":
            MessageLookupByLibrary.simpleMessage("エラー 20110：電話番号が無効です"),
        "errorPhoneSmsDelivery":
            MessageLookupByLibrary.simpleMessage("エラー 10003：SMSの送信に失敗しました"),
        "errorPhoneVerificationCodeExpired":
            MessageLookupByLibrary.simpleMessage("期限切れ"),
        "errorPhoneVerificationCodeInvalid":
            MessageLookupByLibrary.simpleMessage("エラー 20113：電話番号認証コードが無効です"),
        "errorPinCheckTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "入力ミスが5回に達したため一時的にロックします。24時間後にもう一度試してください。"),
        "errorPinIncorrect":
            MessageLookupByLibrary.simpleMessage("PINコードが違います"),
        "errorPinIncorrectWithTimes": m19,
        "errorRecaptchaIsInvalid":
            MessageLookupByLibrary.simpleMessage("エラー 10004: CAPTCHAが無効です"),
        "errorServer5xxCode": m20,
        "errorTooManyRequest":
            MessageLookupByLibrary.simpleMessage("エラー 429: レート制限を超過しています"),
        "errorTooManyStickers":
            MessageLookupByLibrary.simpleMessage("エラー 20126: スタンプが多すぎます"),
        "errorTooSmallTransferAmount":
            MessageLookupByLibrary.simpleMessage("送金数量"),
        "errorTooSmallWithdrawAmount":
            MessageLookupByLibrary.simpleMessage("エラー 20127: 出金額が小さすぎます"),
        "errorTranscriptForward":
            MessageLookupByLibrary.simpleMessage("添付ファイルはすべてダウンロード後、転送してください。"),
        "errorUnableToOpenMedia":
            MessageLookupByLibrary.simpleMessage("メディアを開くことができるアプリがありません"),
        "errorUnknownWithCode": m21,
        "errorUnknownWithMessage": m22,
        "errorUsedPhone": MessageLookupByLibrary.simpleMessage(
            "エラー20122：携帯が第三者によって利用されています。"),
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("ユーザーIDが無効です"),
        "errorWithdrawalMemoFormatIncorrect":
            MessageLookupByLibrary.simpleMessage("メモ"),
        "exit": MessageLookupByLibrary.simpleMessage("退出"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("グループから退出"),
        "file": MessageLookupByLibrary.simpleMessage("ファイル"),
        "fileChooserError": MessageLookupByLibrary.simpleMessage("ファイル選択エラー"),
        "fileDoesNotExist": MessageLookupByLibrary.simpleMessage("ファイルが存在しません"),
        "fileError": MessageLookupByLibrary.simpleMessage("ファイルエラー"),
        "files": MessageLookupByLibrary.simpleMessage("ファイル"),
        "followSystem": MessageLookupByLibrary.simpleMessage("システム設定に従う"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("Facebookをフォロー"),
        "followUsOnTwitter":
            MessageLookupByLibrary.simpleMessage("Twitterをフォロー"),
        "formatNotSupported":
            MessageLookupByLibrary.simpleMessage("サポートされていないフォーマットです"),
        "forward": MessageLookupByLibrary.simpleMessage("転送"),
        "from": MessageLookupByLibrary.simpleMessage("From"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("From:"),
        "groupCantSend": MessageLookupByLibrary.simpleMessage(
            "参加者ではないため、このグループにメッセージを送ることができません。"),
        "groupName": MessageLookupByLibrary.simpleMessage("グループ名"),
        "groupParticipants": MessageLookupByLibrary.simpleMessage("参加者"),
        "groupPopMenuMessage": m23,
        "groupPopMenuRemove": m24,
        "groups": MessageLookupByLibrary.simpleMessage("グループ"),
        "groupsInCommon": MessageLookupByLibrary.simpleMessage("共通のグループ"),
        "help": MessageLookupByLibrary.simpleMessage("ヘルプ"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("ヘルプセンター"),
        "hideMixin": MessageLookupByLibrary.simpleMessage("非表示"),
        "hour": m25,
        "ignoreThisVersion": MessageLookupByLibrary.simpleMessage("最新版を無視"),
        "image": MessageLookupByLibrary.simpleMessage("画像"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("ファイルをバックアップ"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("動画"),
        "initializing": MessageLookupByLibrary.simpleMessage("初期化中…"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "リンクを知っている人はだれでも参加可能です、信頼できる人だけに共有してください"),
        "inviteToGroupViaLink":
            MessageLookupByLibrary.simpleMessage("リンクを使って招待する"),
        "joinGroupWithPlus": MessageLookupByLibrary.simpleMessage("グループに参加"),
        "joinedIn": m26,
        "landingDeleteContent": m27,
        "landingInvitationDialogContent": m28,
        "landingValidationTitle": m29,
        "learnMore": MessageLookupByLibrary.simpleMessage("もっとみる"),
        "less": MessageLookupByLibrary.simpleMessage("少なく"),
        "light": MessageLookupByLibrary.simpleMessage("昼間モード"),
        "live": MessageLookupByLibrary.simpleMessage("ライブ配信"),
        "loading": MessageLookupByLibrary.simpleMessage("ロード中..."),
        "loadingTime":
            MessageLookupByLibrary.simpleMessage("システム時刻が異常です。修正後、使用してください"),
        "locateToChat": MessageLookupByLibrary.simpleMessage("チャットを探す"),
        "location": MessageLookupByLibrary.simpleMessage("位置情報"),
        "logIn": MessageLookupByLibrary.simpleMessage("ログイン"),
        "loginAndAbortAccountDeletion":
            MessageLookupByLibrary.simpleMessage("そのままログインし、アカウント削除をキャンセルします"),
        "loginByQrcode":
            MessageLookupByLibrary.simpleMessage("QRコードでMixinにログインする"),
        "loginByQrcodeTips": MessageLookupByLibrary.simpleMessage(
            "携帯でMixinを開き、画面に表示されるQRコードを読み取り、ログインします"),
        "makeGroupAdmin": MessageLookupByLibrary.simpleMessage("サブリーダー権限を付与"),
        "media": MessageLookupByLibrary.simpleMessage("メディア"),
        "memo": MessageLookupByLibrary.simpleMessage("メモ"),
        "messageE2ee": MessageLookupByLibrary.simpleMessage(
            "この会話へのメッセージはエンドツーエンドで暗号化されています。詳細はタップしてください。"),
        "messageNotFound":
            MessageLookupByLibrary.simpleMessage("メッセージが見つかりません"),
        "messageNotSupport": MessageLookupByLibrary.simpleMessage(
            "このメッセージは未対応であるため、Mixinを最新版にアップデートしてください。"),
        "messagePreviewDescription": MessageLookupByLibrary.simpleMessage(
            "新着メッセージ通知内のメッセージテキストをプレビューします"),
        "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger Desktop"),
        "more": MessageLookupByLibrary.simpleMessage("もっとみる"),
        "muted": MessageLookupByLibrary.simpleMessage("ミュートされました"),
        "myMixinId": m30,
        "myStickers": MessageLookupByLibrary.simpleMessage("マイステッカー"),
        "na": MessageLookupByLibrary.simpleMessage("なし"),
        "name": MessageLookupByLibrary.simpleMessage("名前"),
        "networkError": MessageLookupByLibrary.simpleMessage("ネットワークエラー"),
        "newVersionAvailable": MessageLookupByLibrary.simpleMessage("最新版の公開"),
        "newVersionDescription": m31,
        "next": MessageLookupByLibrary.simpleMessage("次へ"),
        "nextConversation": MessageLookupByLibrary.simpleMessage("次の会話"),
        "noAudio": MessageLookupByLibrary.simpleMessage("音声メッセージがありません"),
        "noCamera": MessageLookupByLibrary.simpleMessage("カメラを認識できません"),
        "noData": MessageLookupByLibrary.simpleMessage("データがありません"),
        "noFiles": MessageLookupByLibrary.simpleMessage("ファイルがありません"),
        "noLinks": MessageLookupByLibrary.simpleMessage("リンクがありません"),
        "noMedia": MessageLookupByLibrary.simpleMessage("メディアがありません"),
        "noNetworkConnection":
            MessageLookupByLibrary.simpleMessage("ネットワーク接続がありません"),
        "noPosts": MessageLookupByLibrary.simpleMessage("投稿がありません"),
        "noResults": MessageLookupByLibrary.simpleMessage("結果なし"),
        "notificationContent":
            MessageLookupByLibrary.simpleMessage("友達からのメッセージを見逃さないで！"),
        "notificationPermissionManually": MessageLookupByLibrary.simpleMessage(
            "通知は許可されていませんので、通知設定から通知を許可してください。"),
        "notifications": MessageLookupByLibrary.simpleMessage("通知"),
        "nowAnAddmin": m32,
        "oneByOneForward":
            MessageLookupByLibrary.simpleMessage("別々のメッセージとして転送する"),
        "oneHour": MessageLookupByLibrary.simpleMessage("1時間"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1週間"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1年間"),
        "openHomePage": MessageLookupByLibrary.simpleMessage("ロボHOME"),
        "openLogDirectory": MessageLookupByLibrary.simpleMessage("ログディレクトリを開く"),
        "originalImage": MessageLookupByLibrary.simpleMessage("オリジナル"),
        "owner": MessageLookupByLibrary.simpleMessage("リーダー"),
        "participantsCount": m33,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("電話番号からの追加"),
        "photos": MessageLookupByLibrary.simpleMessage("画像"),
        "pickAConversation":
            MessageLookupByLibrary.simpleMessage("会話を選択して、メッセージを送信してみましょう"),
        "pinTitle": MessageLookupByLibrary.simpleMessage("ピン留め"),
        "pinnedMessageTitle": m34,
        "preferences": MessageLookupByLibrary.simpleMessage("環境設定"),
        "previousConversation": MessageLookupByLibrary.simpleMessage("過去の会話"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("プライバシーポリシー"),
        "quickSearch": MessageLookupByLibrary.simpleMessage("クイック検索"),
        "quitMixin": MessageLookupByLibrary.simpleMessage("終了"),
        "recaptchaTimeout":
            MessageLookupByLibrary.simpleMessage("Recaptchaがタイムアウトしました"),
        "recentChats": MessageLookupByLibrary.simpleMessage("チャット"),
        "reedit": MessageLookupByLibrary.simpleMessage("再編集"),
        "refresh": MessageLookupByLibrary.simpleMessage("更新"),
        "removeBot": MessageLookupByLibrary.simpleMessage("Myロボから削除"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("リストからチャットを削除"),
        "removeContact": MessageLookupByLibrary.simpleMessage("連絡先を削除"),
        "removeStickers": MessageLookupByLibrary.simpleMessage("ステッカーの削除"),
        "reply": MessageLookupByLibrary.simpleMessage("返信"),
        "report": MessageLookupByLibrary.simpleMessage("報告"),
        "reportAndBlock": MessageLookupByLibrary.simpleMessage("報告してブロックしますか?"),
        "resendCode": MessageLookupByLibrary.simpleMessage("コードを再送する"),
        "resendCodeIn": m35,
        "reset": MessageLookupByLibrary.simpleMessage("リセット"),
        "resetLink": MessageLookupByLibrary.simpleMessage("リンクを取り消す"),
        "retryUploadFailed":
            MessageLookupByLibrary.simpleMessage("アップロードの再試行に失敗しました。"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saveAs": MessageLookupByLibrary.simpleMessage("名前をつけて保存"),
        "saveToCameraRoll": MessageLookupByLibrary.simpleMessage("カメラロールに保存する"),
        "sayHi": MessageLookupByLibrary.simpleMessage("挨拶をしましょう"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "警告：たくさん報告されているユーザーです、詐欺に気をつけてください"),
        "search": MessageLookupByLibrary.simpleMessage("検索"),
        "searchConversation": MessageLookupByLibrary.simpleMessage("メッセージを検索"),
        "searchEmpty":
            MessageLookupByLibrary.simpleMessage("一致する情報は見つかりませんでした"),
        "searchRelatedMessage": m36,
        "secretUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "send": MessageLookupByLibrary.simpleMessage("送る"),
        "sendArchived":
            MessageLookupByLibrary.simpleMessage("1つのZIPファイルにアーカイブ"),
        "sendQuickly": MessageLookupByLibrary.simpleMessage("クイック送信"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("圧縮せずに送信"),
        "sendWithoutSound":
            MessageLookupByLibrary.simpleMessage("通知音を鳴らさずに送信する"),
        "setDisappearingMessageTimeTo": m37,
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID, 名前"),
        "settingBackupTips": MessageLookupByLibrary.simpleMessage(
            "iCloudにチャット履歴をバックアップします。 iPhoneを紛失または機種変更した場合にMixinメッセンジャーを再インストールしてチャット履歴を復元できます。バックアップしたメッセージがiCloudに存在する間はMixinメッセンジャーのエンドツーエンド暗号によって保護されていません。"),
        "share": MessageLookupByLibrary.simpleMessage("共有"),
        "shareApps": MessageLookupByLibrary.simpleMessage("アプリを共有"),
        "shareError": MessageLookupByLibrary.simpleMessage("エラーを共有"),
        "shareLink": MessageLookupByLibrary.simpleMessage("リンクをシェアする"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("写真や動画"),
        "show": MessageLookupByLibrary.simpleMessage("表示"),
        "showAvatar": MessageLookupByLibrary.simpleMessage("アバターの表示"),
        "showMixin": MessageLookupByLibrary.simpleMessage("表示"),
        "signIn": MessageLookupByLibrary.simpleMessage("ログイン"),
        "signOut": MessageLookupByLibrary.simpleMessage("サインアウト"),
        "signWithPhoneNumber":
            MessageLookupByLibrary.simpleMessage("電話番号でログイン"),
        "signWithQrcode": MessageLookupByLibrary.simpleMessage("QRコードでログイン"),
        "sticker": MessageLookupByLibrary.simpleMessage("スタンプ"),
        "stickerAlbumDetail": MessageLookupByLibrary.simpleMessage("スタンプアルバム"),
        "stickerStore": MessageLookupByLibrary.simpleMessage("スタンプストア"),
        "storageAutoDownloadDescription":
            MessageLookupByLibrary.simpleMessage("メディアの自動ダウンロード設定を変更する"),
        "storageUsage": MessageLookupByLibrary.simpleMessage("ストレージ使用率"),
        "strangerHint":
            MessageLookupByLibrary.simpleMessage("連絡先にない相手からのメッセージです"),
        "strangers": MessageLookupByLibrary.simpleMessage("連絡先にない相手"),
        "successful": MessageLookupByLibrary.simpleMessage("成功"),
        "termsOfService": MessageLookupByLibrary.simpleMessage("利用規約"),
        "text": MessageLookupByLibrary.simpleMessage("テキスト"),
        "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
        "thisMessageWasDeleted":
            MessageLookupByLibrary.simpleMessage("このメッセージは削除されています"),
        "time": MessageLookupByLibrary.simpleMessage("日時"),
        "today": MessageLookupByLibrary.simpleMessage("今日"),
        "toggleChatInfo": MessageLookupByLibrary.simpleMessage("チャット情報のオン/オフ"),
        "transactionId": MessageLookupByLibrary.simpleMessage("トランザクションID"),
        "transactions": MessageLookupByLibrary.simpleMessage("もらった・あげたコイン💰"),
        "transcript": MessageLookupByLibrary.simpleMessage("メッセージ履歴"),
        "transfer": MessageLookupByLibrary.simpleMessage("送金"),
        "turnOnNotifications": MessageLookupByLibrary.simpleMessage("通知をオンにする"),
        "typeMessage": MessageLookupByLibrary.simpleMessage("メッセージを入力"),
        "unableToOpenFile": m38,
        "unblock": MessageLookupByLibrary.simpleMessage("ブロックを解除"),
        "unitDay": m39,
        "unitHour": m40,
        "unitMinute": m41,
        "unitSecond": m42,
        "unitWeek": m43,
        "unmute": MessageLookupByLibrary.simpleMessage("ミュート解除"),
        "unpin": MessageLookupByLibrary.simpleMessage("ピン留めを止める"),
        "unpinAllMessages":
            MessageLookupByLibrary.simpleMessage("全てのメッセージのピン留めを解除する"),
        "unpinAllMessagesConfirmation":
            MessageLookupByLibrary.simpleMessage("全てのメッセージのピン留めを解除しますか？"),
        "unreadMessages": MessageLookupByLibrary.simpleMessage("新しいメッセージ"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("ユーザーが見つかりませんでした"),
        "valueNow": m44,
        "valueThen": m45,
        "video": MessageLookupByLibrary.simpleMessage("動画"),
        "videos": MessageLookupByLibrary.simpleMessage("動画"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("このメッセージを待っています。"),
        "webview2RuntimeInstallDescription": MessageLookupByLibrary.simpleMessage(
            "このデバイスには、WebView2 Runtimeコンポーネントがインストールされていません。先にWebView2 Runtimeをダウンロードし、インストールしてください。"),
        "webviewRuntimeUnavailable":
            MessageLookupByLibrary.simpleMessage("WebView runtimeは利用できません"),
        "whatsYourName": MessageLookupByLibrary.simpleMessage("お名前は何ですか？"),
        "writeCircles": MessageLookupByLibrary.simpleMessage("リストの変更"),
        "you": MessageLookupByLibrary.simpleMessage("自分"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("このメッセージを削除しました。")
      };
}
