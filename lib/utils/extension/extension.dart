import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:ulid/ulid.dart';
import 'package:uuid/uuid.dart';

import '../../account/account_server.dart';
import '../../db/dao/snapshot_dao.dart';
import '../../db/database.dart';
import '../../generated/l10n.dart';
import '../../ui/home/bloc/multi_auth_cubit.dart';
import '../../widgets/brightness_observer.dart';
import '../audio_message_player/audio_message_service.dart';

export 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show UuidHashcodeExtension;
export 'package:provider/provider.dart' show ReadContext, WatchContext;

export '../../crypto/attachment/crypto_attachment.dart'
    show EncryptAttachmentStreamExtension, DecryptAttachmentStreamExtension;
export '../../db/dao/transcript_message_dao.dart'
    show TranscriptMessageItemExtension;
export '../../db/extension/conversation.dart' show ConversationItemExtension;
export '../../db/extension/message.dart'
    show MessageItemExtension, QuoteMessageItemExtension;
export '../../db/extension/message_category.dart' show MessageCategoryExtension;
export '../../db/extension/user.dart' show UserExtension;
export '../action_utils.dart' show OpenUriExtension;
export '../datetime_format_utils.dart'
    show DateTimeExtension, StringEpochNanoExtension;
export 'src/errors.dart';
export 'src/platforms.dart';

part 'src/db.dart';
part 'src/duration.dart';
part 'src/file.dart';
part 'src/image.dart';
part 'src/info.dart';
part 'src/iterable.dart';
part 'src/key_event.dart';
part 'src/markdown.dart';
part 'src/number.dart';
part 'src/provider.dart';
part 'src/regexp.dart';
part 'src/stream.dart';
part 'src/string.dart';
part 'src/ui.dart';

void importExtension() {}
