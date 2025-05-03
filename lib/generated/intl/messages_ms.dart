// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ms locale. All the
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
  String get localeName => 'ms';

  static String m2(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: 'Padamkan ${arg0} mesej?')}";

  static String m3(arg0, arg1) => "${arg0} menambahkan ${arg1}";

  static String m4(arg0) => "Tinggal ${arg0}";

  static String m5(arg0) =>
      "${arg0} menyertai kumpulan melalui pautan jemputan";

  static String m6(arg0, arg1) => "${arg0} mengalih keluar ${arg1}";

  static String m8(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} Perbualan')}";

  static String m9(arg0) => "Lingkaran ${arg0}";

  static String m10(arg0) => "Mixin ID: ${arg0}";

  static String m19(arg0) =>
      "RALAT 10006: Sila kemas kini Mixin(${arg0}) untuk terus menggunakan perkhidmatan ini.";

  static String m20(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: 'RALAT 20119: PIN tidak betul. Anda masih mempunyai ${arg0} peluang. Sila tunggu selama 24 jam untuk cuba lagi kemudian.')}";

  static String m21(arg0) => "Pelayan sedang dalam penyelenggaraan: ${arg0}";

  static String m22(arg0) => "RALAT: ${arg0}";

  static String m23(arg0) => "RALAT: ${arg0}";

  static String m24(arg0) => "Mesej ${arg0}";

  static String m25(arg0) => "Alih keluar ${arg0}";

  static String m26(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} Jam')}";

  static String m27(arg0) => "Menyertai ${arg0}";

  static String m29(arg0) =>
      "Kami akan menghantar kod 4 digit ke nombor telefon anda ${arg0}, sila masukkan kod di skrin seterusnya.";

  static String m30(arg0) =>
      "Masukkan kod 4 digit yang dihantar kepada anda di ${arg0}";

  static String m32(arg0) => "ID Mixin Saya: ${arg0}";

  static String m37(count, arg0, arg1) =>
      "${Intl.plural(count, one: 'null', other: '${arg0}/${arg1} pengesahan')}";

  static String m39(arg0) => "Hantar semula kod dalam ${arg0} s";

  static String m40(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} mesej berkaitan')}";

  static String m43(arg0, arg1) =>
      "Adakah anda pasti mahu menghantar ${arg0} dari ${arg1}?";

  static String m44(arg0) => "Adakah anda pasti mahu menghantar ${arg0}?";

  static String m51(arg0) =>
      "Versi semasa (${arg0}) tidak lagi tersedia!\nSila klik Kemas kini di bawah untuk mengemas kini ke versi terbaharu dari Google Play.";

  static String m52(arg0) => "nilai sekarang ${arg0}";

  static String m53(arg0) => "nilai maka ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Mengenai"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("Akses dinafikan"),
        "account": MessageLookupByLibrary.simpleMessage("Akaun"),
        "addContact": MessageLookupByLibrary.simpleMessage("Tambah Kenalan"),
        "addGroupDescription": MessageLookupByLibrary.simpleMessage(
            "Tambahkan keterangan kumpulan"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Tambah Peserta"),
        "addStickerFailed":
            MessageLookupByLibrary.simpleMessage("Penambahan pelekat gagal"),
        "address": MessageLookupByLibrary.simpleMessage("Alamat"),
        "admin": MessageLookupByLibrary.simpleMessage("pentadbir"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("berkongsi kenalan"),
        "appearance": MessageLookupByLibrary.simpleMessage("Penampilan"),
        "audio": MessageLookupByLibrary.simpleMessage("Audio"),
        "block": MessageLookupByLibrary.simpleMessage("Sekat"),
        "botNotFound":
            MessageLookupByLibrary.simpleMessage("Aplikasi tidak dijumpai"),
        "bots": MessageLookupByLibrary.simpleMessage("BOT"),
        "botsTitle": MessageLookupByLibrary.simpleMessage("Bot"),
        "canNotRecognizeQrCode": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat mengenali kod QR"),
        "cancel": MessageLookupByLibrary.simpleMessage("Batal"),
        "card": MessageLookupByLibrary.simpleMessage("Kad"),
        "change": MessageLookupByLibrary.simpleMessage("Ubah"),
        "chatDeleteMessage": m2,
        "chatGroupAdd": m3,
        "chatGroupExit": m4,
        "chatGroupJoin": m5,
        "chatGroupRemove": m6,
        "chatNotSupportUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
        "circleSubtitle": m8,
        "circleTitle": m9,
        "circles": MessageLookupByLibrary.simpleMessage("Lingkaran"),
        "clear": MessageLookupByLibrary.simpleMessage("Kosong"),
        "clearChat": MessageLookupByLibrary.simpleMessage("Kosongkan Sembang"),
        "confirm": MessageLookupByLibrary.simpleMessage("Sahkan"),
        "contact": MessageLookupByLibrary.simpleMessage("Kenalan"),
        "contactMixinId": m10,
        "contactMuteTitle": MessageLookupByLibrary.simpleMessage(
            "Senyapkan pemberitahuan untuk…"),
        "contentTooLong":
            MessageLookupByLibrary.simpleMessage("Kandungan terlalu lama"),
        "contentVoice":
            MessageLookupByLibrary.simpleMessage("[Panggilan suara]"),
        "continueText": MessageLookupByLibrary.simpleMessage("Teruskan"),
        "conversation": MessageLookupByLibrary.simpleMessage("Perbualan"),
        "copy": MessageLookupByLibrary.simpleMessage("Salinan"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("Salin pautan"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Salin pautan"),
        "create": MessageLookupByLibrary.simpleMessage("Buat"),
        "dataAndStorageUsage":
            MessageLookupByLibrary.simpleMessage("Penggunaan Data dan Storan"),
        "dataError": MessageLookupByLibrary.simpleMessage("Kesalahan data"),
        "databaseUpgradeTips": MessageLookupByLibrary.simpleMessage(
            "Pangkalan data sedang ditingkatkan, mungkin memerlukan beberapa minit, jangan tutup Aplikasi ini."),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Padamkan untuk Semua Orang"),
        "deleteForMe":
            MessageLookupByLibrary.simpleMessage("Padamkan untuk saya"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("Padam Kumpulan"),
        "deposit": MessageLookupByLibrary.simpleMessage("Deposit"),
        "developer": MessageLookupByLibrary.simpleMessage("Pemaju"),
        "dismissAsAdmin":
            MessageLookupByLibrary.simpleMessage("Ketepikan pentadbir"),
        "done": MessageLookupByLibrary.simpleMessage("Selesai"),
        "durationIsTooShort":
            MessageLookupByLibrary.simpleMessage("Jangka masa terlalu pendek"),
        "editCircleName":
            MessageLookupByLibrary.simpleMessage("Edit Nama Lingkaran"),
        "editConversations":
            MessageLookupByLibrary.simpleMessage("Edit Perbualan"),
        "editGroupDescription":
            MessageLookupByLibrary.simpleMessage("Edit keterangan kumpulan"),
        "editGroupName": MessageLookupByLibrary.simpleMessage("Edit Nama"),
        "editName": MessageLookupByLibrary.simpleMessage("Edit Nama"),
        "enablePushNotification":
            MessageLookupByLibrary.simpleMessage("Hidupkan Pemberitahuan"),
        "enterYourPhoneNumber": MessageLookupByLibrary.simpleMessage(
            "Masukkan nombor telefon bimbit anda"),
        "errorAuthentication": MessageLookupByLibrary.simpleMessage(
            "RALAT 401: Log masuk untuk meneruskan"),
        "errorBadData": MessageLookupByLibrary.simpleMessage(
            "RALAT 10002: Data permintaan mempunyai medan yang tidak sah"),
        "errorBlockchain": MessageLookupByLibrary.simpleMessage(
            "RALAT 30100: Rantai blok tidak diselaraskan, sila cuba sebentar lagi."),
        "errorConnectionTimeout": MessageLookupByLibrary.simpleMessage(
            "Tamat masa sambungan rangkaian"),
        "errorFullGroup": MessageLookupByLibrary.simpleMessage(
            "RALAT 20116: Kumpulan sembang penuh."),
        "errorInsufficientBalance": MessageLookupByLibrary.simpleMessage(
            "RALAT 20117: Baki tidak mencukupi"),
        "errorInvalidAddressPlain": MessageLookupByLibrary.simpleMessage(
            "RALAT 30102: Format alamat tidak sah."),
        "errorInvalidCodeTooFrequent": MessageLookupByLibrary.simpleMessage(
            "RALAT 20129: Hantar kod pengesahan terlalu kerap, sila cuba sebentar lagi."),
        "errorInvalidPinFormat": MessageLookupByLibrary.simpleMessage(
            "RALAT 20118: Format PIN tidak sah"),
        "errorNotFound":
            MessageLookupByLibrary.simpleMessage("RALAT 404: Tidak ditemui"),
        "errorNotSupportedAudioFormat": MessageLookupByLibrary.simpleMessage(
            "Tidak disokong format audio, sila buka oleh aplikasi lain."),
        "errorNumberReachedLimit": MessageLookupByLibrary.simpleMessage(
            "RALAT 20132: Angka telah mencapai had."),
        "errorOldVersion": m19,
        "errorOpenLocation": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat mencari aplikasi peta"),
        "errorPermission": MessageLookupByLibrary.simpleMessage(
            "Sila buka kebenaran yang diperlukan"),
        "errorPhoneInvalidFormat": MessageLookupByLibrary.simpleMessage(
            "RALAT 20110: Nombor telefon tidak sah"),
        "errorPhoneSmsDelivery": MessageLookupByLibrary.simpleMessage(
            "RALAT 10003: Gagal menghantar SMS"),
        "errorPhoneVerificationCodeExpired":
            MessageLookupByLibrary.simpleMessage(
                "RALAT 20114: Kod pengesahan telefon yang telah tamat tempoh"),
        "errorPhoneVerificationCodeInvalid":
            MessageLookupByLibrary.simpleMessage(
                "RALAT 20113: Kod pengesahan telefon tidak sah"),
        "errorPinCheckTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "Anda telah mencuba lebih dari 5 kali, sila tunggu sekurang-kurangnya 24 jam untuk mencuba lagi."),
        "errorPinIncorrect": MessageLookupByLibrary.simpleMessage(
            "RALAT 20119: PIN tidak betul"),
        "errorPinIncorrectWithTimes": m20,
        "errorRecaptchaIsInvalid": MessageLookupByLibrary.simpleMessage(
            "RALAT 10004: Recaptcha tidak sah"),
        "errorServer5xxCode": m21,
        "errorTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "RALAT 429: Had kadar melebihi"),
        "errorTooManyStickers": MessageLookupByLibrary.simpleMessage(
            "RALAT 20126: Terlalu banyak pelekat"),
        "errorTooSmallTransferAmount": MessageLookupByLibrary.simpleMessage(
            "RALAT 20120: Jumlahnya terlalu kecil"),
        "errorTooSmallWithdrawAmount": MessageLookupByLibrary.simpleMessage(
            "RALAT 20127: Jumlah penarikan terlalu kecil"),
        "errorUnableToOpenMedia": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat mencari aplikasi yang dapat buka media ini."),
        "errorUnknownWithCode": m22,
        "errorUnknownWithMessage": m23,
        "errorUsedPhone": MessageLookupByLibrary.simpleMessage(
            "RALAT 20122: Telefon digunakan oleh orang lain."),
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("Id pengguna tidak sah"),
        "errorWithdrawalMemoFormatIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "RALAT 20131: Penarikan format memo tidak betul."),
        "exit": MessageLookupByLibrary.simpleMessage("Keluar"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("Keluar Kumpulan"),
        "fee": MessageLookupByLibrary.simpleMessage("Bayaran"),
        "file": MessageLookupByLibrary.simpleMessage("Fail"),
        "fileChooserError":
            MessageLookupByLibrary.simpleMessage("Ralat pemilih fail"),
        "fileDoesNotExist":
            MessageLookupByLibrary.simpleMessage("Fail tidak wujud"),
        "fileError": MessageLookupByLibrary.simpleMessage("Ralat fail"),
        "files": MessageLookupByLibrary.simpleMessage("Fail"),
        "followSystem": MessageLookupByLibrary.simpleMessage("Ikut Sistem"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("Ikuti kami di Facebook"),
        "followUsOnX": MessageLookupByLibrary.simpleMessage("Ikuti kami di X"),
        "formatNotSupported":
            MessageLookupByLibrary.simpleMessage("Format tidak disokong"),
        "forward": MessageLookupByLibrary.simpleMessage("Ke hadapan"),
        "groupAlreadyIn": MessageLookupByLibrary.simpleMessage(
            "Anda sudah berada dalam kumpulan"),
        "groupCantSend": MessageLookupByLibrary.simpleMessage(
            "Anda tidak dapat menghantar mesej kepada kumpulan ini kerana anda bukan lagi peserta."),
        "groupName": MessageLookupByLibrary.simpleMessage("Nama kumpulan"),
        "groupPopMenuMessage": m24,
        "groupPopMenuRemove": m25,
        "helpCenter": MessageLookupByLibrary.simpleMessage("Pusat bantuan"),
        "hour": m26,
        "initializing": MessageLookupByLibrary.simpleMessage("Memulakan…"),
        "invalidStickerFormat":
            MessageLookupByLibrary.simpleMessage("Format pelekat tidak sah"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "Sesiapa sahaja yang mempunyai Mixin boleh mengikuti pautan ini untuk menyertai kumpulan ini. Kongsi sahaja dengan orang yang anda percayai."),
        "inviteToGroupViaLink": MessageLookupByLibrary.simpleMessage(
            "Jemput ke Kumpulan melalui Pautan"),
        "joinedIn": m27,
        "landingInvitationDialogContent": m29,
        "landingValidationTitle": m30,
        "learnMore":
            MessageLookupByLibrary.simpleMessage("Ketahui Lebih Lanjut"),
        "live": MessageLookupByLibrary.simpleMessage("Langsung"),
        "loadingTime": MessageLookupByLibrary.simpleMessage(
            "Waktu sistem tidak biasa, sila terus gunakan lagi selepas pembetulan"),
        "location": MessageLookupByLibrary.simpleMessage("Lokasi"),
        "logIn": MessageLookupByLibrary.simpleMessage("Log masuk"),
        "makeGroupAdmin":
            MessageLookupByLibrary.simpleMessage("Buat pentadbir kumpulan"),
        "media": MessageLookupByLibrary.simpleMessage("Media"),
        "memo": MessageLookupByLibrary.simpleMessage("Memo"),
        "messageE2ee": MessageLookupByLibrary.simpleMessage(
            "Mesej ke perbualan ini disulitkan dari hujung ke hujung, ketuk untuk maklumat lebih lanjut."),
        "messageNotFound":
            MessageLookupByLibrary.simpleMessage("Mesej tidak dijumpai"),
        "messageNotSupport": MessageLookupByLibrary.simpleMessage(
            "Mesej jenis ini tidak disokong, sila tingkatkan Mixin ke versi terkini."),
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Desktop Mixin Messenger"),
        "more": MessageLookupByLibrary.simpleMessage("Lebih banyak lagi"),
        "multisigTransaction":
            MessageLookupByLibrary.simpleMessage("Transaksi Multisig"),
        "myMixinId": m32,
        "na": MessageLookupByLibrary.simpleMessage("N/A"),
        "name": MessageLookupByLibrary.simpleMessage("Nama"),
        "networkError": MessageLookupByLibrary.simpleMessage("Ralat rangkaian"),
        "next": MessageLookupByLibrary.simpleMessage("Seterusnya"),
        "noAudio": MessageLookupByLibrary.simpleMessage("TIADA AUDIO"),
        "noCamera": MessageLookupByLibrary.simpleMessage("Tiada kamera"),
        "noFiles": MessageLookupByLibrary.simpleMessage("TIADA FAIL"),
        "noLinks": MessageLookupByLibrary.simpleMessage("TIADA Pautan"),
        "noMedia": MessageLookupByLibrary.simpleMessage("TIADA MEDIA"),
        "noNetworkConnection":
            MessageLookupByLibrary.simpleMessage("Tiada sambungan rangkaian"),
        "noPosts": MessageLookupByLibrary.simpleMessage("TIADA POST"),
        "noResults": MessageLookupByLibrary.simpleMessage("Tiada keputusan"),
        "notFound": MessageLookupByLibrary.simpleMessage("Tidak ditemui"),
        "notifications": MessageLookupByLibrary.simpleMessage("Pemberitahuan"),
        "oneHour": MessageLookupByLibrary.simpleMessage("1 jam"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1 minggu"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1 tahun"),
        "openHomePage":
            MessageLookupByLibrary.simpleMessage("Buka laman Utama"),
        "owner": MessageLookupByLibrary.simpleMessage("pemilik"),
        "pendingConfirmation": m37,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Nombor telefon"),
        "photos": MessageLookupByLibrary.simpleMessage("Foto"),
        "post": MessageLookupByLibrary.simpleMessage("Kirim"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Dasar Privasi"),
        "raw": MessageLookupByLibrary.simpleMessage("Mentah"),
        "rebate": MessageLookupByLibrary.simpleMessage("Rebat"),
        "recaptchaTimeout":
            MessageLookupByLibrary.simpleMessage("Tamat masa Recaptcha"),
        "receiver": MessageLookupByLibrary.simpleMessage("Penerima"),
        "recentChats": MessageLookupByLibrary.simpleMessage("SEMBANG"),
        "refresh": MessageLookupByLibrary.simpleMessage("Segarkan"),
        "removeBot": MessageLookupByLibrary.simpleMessage("Keluarkan Bot"),
        "removeContact": MessageLookupByLibrary.simpleMessage("Buang kenalan"),
        "report": MessageLookupByLibrary.simpleMessage("Lapor"),
        "resendCode": MessageLookupByLibrary.simpleMessage("Hantar semula kod"),
        "resendCodeIn": m39,
        "retry": MessageLookupByLibrary.simpleMessage("CUBA SEMULA"),
        "retryUploadFailed":
            MessageLookupByLibrary.simpleMessage("Gagal memuat naik semula."),
        "revokeMultisigTransaction": MessageLookupByLibrary.simpleMessage(
            "Batalkan Urus Niaga Multisig"),
        "save": MessageLookupByLibrary.simpleMessage("Jimat"),
        "sayHi": MessageLookupByLibrary.simpleMessage("Ucap hai"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "Amaran: Ramai pengguna melaporkan akaun ini sebagai penipuan. Sila berhati-hati, terutamanya jika ia meminta wang kepada anda"),
        "search": MessageLookupByLibrary.simpleMessage("Cari"),
        "searchConversation":
            MessageLookupByLibrary.simpleMessage("Cari Perbualan"),
        "searchRelatedMessage": m40,
        "secretUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "security": MessageLookupByLibrary.simpleMessage("Keselamatan"),
        "select": MessageLookupByLibrary.simpleMessage("Pilih"),
        "send": MessageLookupByLibrary.simpleMessage("Hantar"),
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID, Nama"),
        "share": MessageLookupByLibrary.simpleMessage("Berkongsi"),
        "shareError": MessageLookupByLibrary.simpleMessage("Kongsi ralat"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Kongsi pautan"),
        "shareMessageDescription": m43,
        "shareMessageDescriptionEmpty": m44,
        "sharedMedia": MessageLookupByLibrary.simpleMessage("Media Berkongsi"),
        "show": MessageLookupByLibrary.simpleMessage("Tunjuk"),
        "signIn": MessageLookupByLibrary.simpleMessage("Log masuk"),
        "signWithMobileNumber": MessageLookupByLibrary.simpleMessage(
            "Log masuk dengan nombor telefon"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "sticker": MessageLookupByLibrary.simpleMessage("Pelekat"),
        "stickerAddInvalidSize": MessageLookupByLibrary.simpleMessage(
            "Memerlukan saiz fail pelekat lebih besar daripada 1KB dan kurang dari 1MB, lebar dan tinggi antara 128px dan 1024px."),
        "storageUsage":
            MessageLookupByLibrary.simpleMessage("Penggunaan Storan"),
        "successful": MessageLookupByLibrary.simpleMessage("Berjaya"),
        "termsOfService":
            MessageLookupByLibrary.simpleMessage("Terma Perkhidmatan"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "thisMessageWasDeleted":
            MessageLookupByLibrary.simpleMessage("Mesej ini telah dipadamkan"),
        "time": MessageLookupByLibrary.simpleMessage("Masa"),
        "today": MessageLookupByLibrary.simpleMessage("Hari ini"),
        "trace": MessageLookupByLibrary.simpleMessage("Jejak"),
        "transactionHash":
            MessageLookupByLibrary.simpleMessage("Urus niaga Cincangan"),
        "transactionId": MessageLookupByLibrary.simpleMessage("Id Urus Niaga"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Jenis Transaksi"),
        "transactions": MessageLookupByLibrary.simpleMessage("Urus Niaga"),
        "transfer": MessageLookupByLibrary.simpleMessage("Pindah"),
        "typeMessage": MessageLookupByLibrary.simpleMessage("Taipkan mesej"),
        "unblock": MessageLookupByLibrary.simpleMessage("Buka sekatan"),
        "unmute": MessageLookupByLibrary.simpleMessage("Nyahsenyap"),
        "updateMixin": MessageLookupByLibrary.simpleMessage("Kemas kini Mixin"),
        "updateMixinDescription": m51,
        "upgrading": MessageLookupByLibrary.simpleMessage("Menaik taraf"),
        "userNotFound":
            MessageLookupByLibrary.simpleMessage("Pengguna tidak ditemui"),
        "valueNow": m52,
        "valueThen": m53,
        "verifyPin": MessageLookupByLibrary.simpleMessage("Sahkan PIN"),
        "video": MessageLookupByLibrary.simpleMessage("Video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video"),
        "whatsYourName":
            MessageLookupByLibrary.simpleMessage("Siapa nama awak?"),
        "withdrawal": MessageLookupByLibrary.simpleMessage("Pengeluaran"),
        "you": MessageLookupByLibrary.simpleMessage("Anda"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("Anda memadamkan mesej ini")
      };
}
