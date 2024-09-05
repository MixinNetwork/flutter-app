// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a in locale. All the
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
  String get localeName => 'in';

  static String m2(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: 'Hapus ${arg0} pesan?')}";

  static String m3(arg0, arg1) => "${arg0} menambahkan ${arg1}";

  static String m4(arg0) => "${arg0} keluar";

  static String m5(arg0) =>
      "${arg0} bergabung dengan grup melalui tautan undangan";

  static String m6(arg0, arg1) => "${arg0} menghapus ${arg1}";

  static String m8(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} Percakapan')}";

  static String m9(arg0) => "Lingkaran ${arg0}";

  static String m10(arg0) => "Mixin ID: ${arg0}";

  static String m19(arg0) =>
      "KESALAHAN 10006: Harap perbarui Mixin(${arg0}) untuk terus menggunakan layanan.";

  static String m20(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: 'KESALAHAN 20119: PIN salah. Anda masih memiliki ${arg0} kesempatan. Harap tunggu 24 jam untuk mencoba lagi nanti.')}";

  static String m21(arg0) => "Server sedang dalam pemeliharaan: ${arg0}";

  static String m22(arg0) => "KESALAHAN: ${arg0}";

  static String m23(arg0) => "KESALAHAN: ${arg0}";

  static String m24(arg0) => "Kirim pesan ke ${arg0}";

  static String m25(arg0) => "Hapus ${arg0}";

  static String m26(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} Jam')}";

  static String m27(arg0) => "Bergabung di ${arg0}";

  static String m29(arg0) =>
      "Kami akan mengirim kode 4 digit ke nomor telepon Anda ${arg0}, harap masukkan kode tersebut pada layar berikutnya.";

  static String m30(arg0) =>
      "Masukkan kode 4 digit yang dikirim kepada Anda di ${arg0}";

  static String m32(arg0) => "ID Mixin saya: ${arg0}";

  static String m37(count, arg0, arg1) =>
      "${Intl.plural(count, one: 'null', other: '${arg0}/${arg1} konfirmasi')}";

  static String m39(arg0) => "Kirim ulang kode dalam ${arg0} d";

  static String m40(count, arg0) =>
      "${Intl.plural(count, one: 'null', other: '${arg0} pesan terkait')}";

  static String m43(arg0, arg1) => "Yakin ingin mengirim ${arg0} dari ${arg1}?";

  static String m44(arg0) => "Yakin ingin mengirim ${arg0}?";

  static String m51(arg0) =>
      "Versi saat ini (${arg0}) tidak lagi tersedia!\nHarap klik Perbarui berikut untuk memperbarui ke versi terbaru dari App Store.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Tentang"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("Akses ditolak"),
        "account": MessageLookupByLibrary.simpleMessage("Akun"),
        "addContact": MessageLookupByLibrary.simpleMessage("Tambahkan Kontak"),
        "addGroupDescription":
            MessageLookupByLibrary.simpleMessage("Tambahkan deskripsi grup"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Tambahkan Peserta"),
        "addStickerFailed":
            MessageLookupByLibrary.simpleMessage("Gagal menambahkan stiker"),
        "address": MessageLookupByLibrary.simpleMessage("Alamat"),
        "admin": MessageLookupByLibrary.simpleMessage("admin"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("berbagi kontak"),
        "appearance": MessageLookupByLibrary.simpleMessage("Tampilan"),
        "audio": MessageLookupByLibrary.simpleMessage("Audio"),
        "block": MessageLookupByLibrary.simpleMessage("Blokir"),
        "botNotFound":
            MessageLookupByLibrary.simpleMessage("Aplikasi tidak ditemukan"),
        "bots": MessageLookupByLibrary.simpleMessage("BOT"),
        "botsTitle": MessageLookupByLibrary.simpleMessage("Bot"),
        "canNotRecognizeQrCode": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat mengenal kode QR"),
        "cancel": MessageLookupByLibrary.simpleMessage("Batal"),
        "card": MessageLookupByLibrary.simpleMessage("Kartu"),
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
        "clear": MessageLookupByLibrary.simpleMessage("Bersihkan"),
        "clearChat": MessageLookupByLibrary.simpleMessage("Bersihkan Obrolan"),
        "confirm": MessageLookupByLibrary.simpleMessage("Konfirmasi"),
        "contact": MessageLookupByLibrary.simpleMessage("Kontak"),
        "contactMixinId": m10,
        "contactMuteTitle":
            MessageLookupByLibrary.simpleMessage("Matikan notifikasi selama…"),
        "contentTooLong":
            MessageLookupByLibrary.simpleMessage("Konten terlalu panjang"),
        "contentVoice":
            MessageLookupByLibrary.simpleMessage("[Panggilan suara]"),
        "continueText": MessageLookupByLibrary.simpleMessage("Lanjutkan"),
        "conversation": MessageLookupByLibrary.simpleMessage("Percakapan"),
        "copy": MessageLookupByLibrary.simpleMessage("Salin"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("Salin Tautan"),
        "create": MessageLookupByLibrary.simpleMessage("Buat"),
        "dataAndStorageUsage": MessageLookupByLibrary.simpleMessage(
            "Penggunaan Data dan Penyimpanan"),
        "dataError": MessageLookupByLibrary.simpleMessage("Kesalahan data"),
        "databaseUpgradeTips": MessageLookupByLibrary.simpleMessage(
            "Database sedang ditingkatkan, mungkin perlu beberapa menit, jangan tutup Aplikasi ini."),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Hapus untuk Semua Orang"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("Hapus untuk saya"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("Hapus Grup"),
        "deposit": MessageLookupByLibrary.simpleMessage("Deposit"),
        "developer": MessageLookupByLibrary.simpleMessage("Pengembang"),
        "dismissAsAdmin":
            MessageLookupByLibrary.simpleMessage("Singkirkan admin"),
        "done": MessageLookupByLibrary.simpleMessage("Selesai"),
        "durationIsTooShort":
            MessageLookupByLibrary.simpleMessage("Durasi terlalu pendek"),
        "editCircleName":
            MessageLookupByLibrary.simpleMessage("Edit Nama Lingkaran"),
        "editConversations":
            MessageLookupByLibrary.simpleMessage("Edit Percakapan"),
        "editGroupDescription":
            MessageLookupByLibrary.simpleMessage("Edit deskripsi grup"),
        "editGroupName": MessageLookupByLibrary.simpleMessage("Edit Nama"),
        "editName": MessageLookupByLibrary.simpleMessage("Edit Nama"),
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("Masukkan nomor ponsel Anda"),
        "errorAuthentication": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 401: Masuk untuk melanjutkan"),
        "errorBadData": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 10002: Data permintaan memiliki bidang yang tidak valid"),
        "errorBlockchain": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 30100: Blockchain tidak sinkron, coba lagi nanti."),
        "errorConnectionTimeout": MessageLookupByLibrary.simpleMessage(
            "Batas waktu sambungan jaringan"),
        "errorFullGroup": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20116: Obrolan grup sudah penuh."),
        "errorInsufficientBalance": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20117: Saldo tidak cukup"),
        "errorInvalidAddressPlain": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 30102: Format alamat tidak valid."),
        "errorInvalidCodeTooFrequent": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20129: Terlalu sering mengirim kode verifikasi, coba lagi nanti."),
        "errorInvalidEmergencyContact": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20130: Kontak darurat tidak valid"),
        "errorInvalidPinFormat": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20118: Format PIN tidak valid"),
        "errorNotFound": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 404: Tidak ditemukan"),
        "errorNotSupportedAudioFormat": MessageLookupByLibrary.simpleMessage(
            "Tidak mendukung format audio, harap buka dengan aplikasi lain."),
        "errorNumberReachedLimit": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20132: Jumlahnya telah mencapai batas."),
        "errorOldVersion": m19,
        "errorOpenLocation": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat menemukan aplikasi peta"),
        "errorPermission": MessageLookupByLibrary.simpleMessage(
            "Harap buka izin yang diperlukan"),
        "errorPhoneInvalidFormat": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20110: Nomor telepon tidak valid"),
        "errorPhoneSmsDelivery": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 10003: Gagal mengirim SMS"),
        "errorPhoneVerificationCodeExpired":
            MessageLookupByLibrary.simpleMessage(
                "KESALAHAN 20114: Kode verifikasi telepon sudah tidak berlaku"),
        "errorPhoneVerificationCodeInvalid":
            MessageLookupByLibrary.simpleMessage(
                "KESALAHAN 20113: Kode verifikasi telepon tidak valid"),
        "errorPinCheckTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "Anda telah mencoba lebih dari 5 kali, harap tunggu setidaknya 24 jam untuk mencoba lagi."),
        "errorPinIncorrect":
            MessageLookupByLibrary.simpleMessage("KESALAHAN 20119: PIN salah"),
        "errorPinIncorrectWithTimes": m20,
        "errorRecaptchaIsInvalid": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 10004: Recaptcha tidak valid"),
        "errorServer5xxCode": m21,
        "errorTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 429: Batas nilai terlampaui"),
        "errorTooManyStickers": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20126: Terlalu banyak stiker"),
        "errorTooSmallTransferAmount": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20120: Jumlahnya terlalu kecil"),
        "errorTooSmallWithdrawAmount": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20127: Jumlah penarikan dana terlalu kecil"),
        "errorUnableToOpenMedia": MessageLookupByLibrary.simpleMessage(
            "Tidak dapat menemukan aplikasi yang dapat membuka media ini."),
        "errorUnknownWithCode": m22,
        "errorUnknownWithMessage": m23,
        "errorUsedPhone": MessageLookupByLibrary.simpleMessage(
            "KESALAHAN 20122: Ponsel digunakan oleh orang lain."),
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("ID pengguna tidak valid"),
        "errorWithdrawalMemoFormatIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "KESALAHAN 20131: Format memo penarikan salah."),
        "exit": MessageLookupByLibrary.simpleMessage("Keluar"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("Keluar dari Grup"),
        "fee": MessageLookupByLibrary.simpleMessage("Biaya"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileChooserError":
            MessageLookupByLibrary.simpleMessage("Kesalahan pemilih file"),
        "fileDoesNotExist":
            MessageLookupByLibrary.simpleMessage("File tidak ada"),
        "fileError": MessageLookupByLibrary.simpleMessage("Kesalahan file"),
        "files": MessageLookupByLibrary.simpleMessage("File"),
        "followSystem": MessageLookupByLibrary.simpleMessage("Otomatis"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("Ikuti kami di Facebook"),
        "followUsOnTwitter":
            MessageLookupByLibrary.simpleMessage("Ikuti kami di Twitter"),
        "formatNotSupported":
            MessageLookupByLibrary.simpleMessage("Format tidak didukung"),
        "forward": MessageLookupByLibrary.simpleMessage("Teruskan"),
        "groupAlreadyIn": MessageLookupByLibrary.simpleMessage(
            "Anda sudah bergabung dalam grup"),
        "groupCantSend": MessageLookupByLibrary.simpleMessage(
            "Anda tidak dapat mengirim pesan ke grup ini karena Anda bukan lagi peserta."),
        "groupName": MessageLookupByLibrary.simpleMessage("Nama Grup"),
        "groupPopMenuMessage": m24,
        "groupPopMenuRemove": m25,
        "helpCenter": MessageLookupByLibrary.simpleMessage("Pusat bantuan"),
        "hour": m26,
        "initializing": MessageLookupByLibrary.simpleMessage("Memulai..."),
        "invalidStickerFormat":
            MessageLookupByLibrary.simpleMessage("Format stiker tidak valid"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "Siapapun yang memiliki Mixin dapat mengikuti tautan ini untuk bergabung dengan grup ini. Hanya bagikan dengan orang yang Anda percaya."),
        "inviteToGroupViaLink": MessageLookupByLibrary.simpleMessage(
            "Undang ke Grup melalui Tautan"),
        "joinedIn": m27,
        "landingInvitationDialogContent": m29,
        "landingValidationTitle": m30,
        "learnMore":
            MessageLookupByLibrary.simpleMessage("Pelajari Selengkapnya"),
        "live": MessageLookupByLibrary.simpleMessage("Siaran Langsung"),
        "loadingTime": MessageLookupByLibrary.simpleMessage(
            "Waktu sistem tidak normal, silakan gunakan lagi setelah perbaikan dilakukan"),
        "location": MessageLookupByLibrary.simpleMessage("Lokasi"),
        "logIn": MessageLookupByLibrary.simpleMessage("Masuk"),
        "makeGroupAdmin":
            MessageLookupByLibrary.simpleMessage("Jadikan admin grup"),
        "media": MessageLookupByLibrary.simpleMessage("Media"),
        "memo": MessageLookupByLibrary.simpleMessage("Memo"),
        "messageE2ee": MessageLookupByLibrary.simpleMessage(
            "Pesan ke percakapan ini dienkripsi end-to-end, ketuk untuk info selengkapnya."),
        "messageNotFound":
            MessageLookupByLibrary.simpleMessage("Pesan tidak ditemukan"),
        "messageNotSupport": MessageLookupByLibrary.simpleMessage(
            "Jenis pesan ini tidak didukung, harap tingkatkan Mixin ke versi terbaru."),
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger Desktop"),
        "more": MessageLookupByLibrary.simpleMessage("Lebih banyak"),
        "multisigTransaction":
            MessageLookupByLibrary.simpleMessage("Transaksi Multisig"),
        "myMixinId": m32,
        "na": MessageLookupByLibrary.simpleMessage("N/A"),
        "name": MessageLookupByLibrary.simpleMessage("Nama"),
        "networkError":
            MessageLookupByLibrary.simpleMessage("Kesalahan jaringan"),
        "next": MessageLookupByLibrary.simpleMessage("Berikutnya"),
        "noAudio": MessageLookupByLibrary.simpleMessage("TIDAK ADA SUARA"),
        "noCamera": MessageLookupByLibrary.simpleMessage("Tidak ada kamera"),
        "noFiles": MessageLookupByLibrary.simpleMessage("TIDAK ADA FILE"),
        "noLinks": MessageLookupByLibrary.simpleMessage("TIDAK ADA TAUTAN"),
        "noMedia": MessageLookupByLibrary.simpleMessage("TIDAK ADA MEDIA"),
        "noNetworkConnection": MessageLookupByLibrary.simpleMessage(
            "Tidak ada sambungan jaringan"),
        "noPosts": MessageLookupByLibrary.simpleMessage("TIDAK ADA POSTINGAN"),
        "noResults": MessageLookupByLibrary.simpleMessage("Tidak ada hasil"),
        "notFound": MessageLookupByLibrary.simpleMessage("Tidak ditemukan"),
        "notificationContent": MessageLookupByLibrary.simpleMessage(
            "Jangan lewatkan pesan dari teman Anda."),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifikasi"),
        "oneHour": MessageLookupByLibrary.simpleMessage("1 Jam"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1 Minggu"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1 Tahun"),
        "openHomePage": MessageLookupByLibrary.simpleMessage("Buka Beranda"),
        "owner": MessageLookupByLibrary.simpleMessage("pemilik"),
        "pendingConfirmation": m37,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Nomor Telepon"),
        "photos": MessageLookupByLibrary.simpleMessage("Foto"),
        "post": MessageLookupByLibrary.simpleMessage("Postingan"),
        "privacyPolicy":
            MessageLookupByLibrary.simpleMessage("Kebijakan Privasi"),
        "raw": MessageLookupByLibrary.simpleMessage("Raw"),
        "rebate": MessageLookupByLibrary.simpleMessage("Potongan harga"),
        "recaptchaTimeout":
            MessageLookupByLibrary.simpleMessage("Batas waktu recaptcha"),
        "receiver": MessageLookupByLibrary.simpleMessage("Penerima"),
        "recentChats": MessageLookupByLibrary.simpleMessage("OBROLAN"),
        "refresh": MessageLookupByLibrary.simpleMessage("Muat ulang"),
        "removeBot": MessageLookupByLibrary.simpleMessage("Hapus Bot"),
        "removeContact": MessageLookupByLibrary.simpleMessage("Hapus kontak"),
        "report": MessageLookupByLibrary.simpleMessage("Laporkan"),
        "resendCode": MessageLookupByLibrary.simpleMessage("Kirim ulang kode"),
        "resendCodeIn": m39,
        "retry": MessageLookupByLibrary.simpleMessage("COBA LAGI"),
        "retryUploadFailed":
            MessageLookupByLibrary.simpleMessage("Unggahan ulang gagal."),
        "revokeMultisigTransaction":
            MessageLookupByLibrary.simpleMessage("Cabut Transaksi Multisig"),
        "save": MessageLookupByLibrary.simpleMessage("Simpan"),
        "sayHi": MessageLookupByLibrary.simpleMessage("Katakan Hai"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "Peringatan: Banyak pengguna yang melaporkan akun ini sebagai scam. Harap berhati-hati, terutama jika meminta uang Anda"),
        "search": MessageLookupByLibrary.simpleMessage("Cari"),
        "searchConversation":
            MessageLookupByLibrary.simpleMessage("Cari Percakapan"),
        "searchRelatedMessage": m40,
        "secretUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "security": MessageLookupByLibrary.simpleMessage("Keamanan"),
        "select": MessageLookupByLibrary.simpleMessage("Pilih"),
        "send": MessageLookupByLibrary.simpleMessage("Kirim"),
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID, Nama"),
        "share": MessageLookupByLibrary.simpleMessage("Bagikan"),
        "shareError":
            MessageLookupByLibrary.simpleMessage("Bagikan kesalahan."),
        "shareLink": MessageLookupByLibrary.simpleMessage("Bagikan Tautan"),
        "shareMessageDescription": m43,
        "shareMessageDescriptionEmpty": m44,
        "sharedMedia": MessageLookupByLibrary.simpleMessage("Media Bersama"),
        "show": MessageLookupByLibrary.simpleMessage("Tampilkan"),
        "signIn": MessageLookupByLibrary.simpleMessage("Masuk"),
        "signWithPhoneNumber":
            MessageLookupByLibrary.simpleMessage("Masuk dengan nomor telepon"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "sticker": MessageLookupByLibrary.simpleMessage("Stiker"),
        "stickerAddInvalidSize": MessageLookupByLibrary.simpleMessage(
            "Memerlukan ukuran file stiker yang lebih besar dari 1KB dan kurang dari 1MB, lebar dan tinggi antara 128px dan 1024px."),
        "storageUsage":
            MessageLookupByLibrary.simpleMessage("Penggunaan Penyimpanan"),
        "successful": MessageLookupByLibrary.simpleMessage("Berhasil"),
        "termsOfService":
            MessageLookupByLibrary.simpleMessage("Ketentuan Layanan"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "thisMessageWasDeleted":
            MessageLookupByLibrary.simpleMessage("Pesan ini telah dihapus"),
        "time": MessageLookupByLibrary.simpleMessage("Waktu"),
        "today": MessageLookupByLibrary.simpleMessage("Hari ini"),
        "transactionHash":
            MessageLookupByLibrary.simpleMessage("Hash Transaksi"),
        "transactionId": MessageLookupByLibrary.simpleMessage("ID Transaksi"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Jenis Transaksi"),
        "transactions": MessageLookupByLibrary.simpleMessage("Transaksi"),
        "transfer": MessageLookupByLibrary.simpleMessage("Transfer"),
        "turnOnNotifications":
            MessageLookupByLibrary.simpleMessage("Aktifkan Notifikasi"),
        "unblock": MessageLookupByLibrary.simpleMessage("Batal Blokir"),
        "unmute": MessageLookupByLibrary.simpleMessage("Suarakan"),
        "updateMixin": MessageLookupByLibrary.simpleMessage("Perbarui Mixin"),
        "updateMixinDescription": m51,
        "upgrading": MessageLookupByLibrary.simpleMessage("Meningkatkan"),
        "userNotFound":
            MessageLookupByLibrary.simpleMessage("Pengguna tidak ditemukan"),
        "verifyPin": MessageLookupByLibrary.simpleMessage("Verifikasikan PIN"),
        "video": MessageLookupByLibrary.simpleMessage("Video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video"),
        "whatsYourName":
            MessageLookupByLibrary.simpleMessage("Siapa nama Anda?"),
        "withdrawal": MessageLookupByLibrary.simpleMessage("Penarikan"),
        "you": MessageLookupByLibrary.simpleMessage("Anda"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("Anda menghapus pesan ini")
      };
}
