import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:platform_ocr/platform_ocr.dart';
// ignore: implementation_imports
import 'package:platform_ocr/src/darwin/bindings.g.dart' as darwin;

import '../../db/ai_database.dart';
import '../../db/database.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart';
import '../../utils/attachment/attachment_util.dart';

const aiImageOcrEngine = 'platform_ocr';
const _kOcrStatusDone = 'done';
const _kOcrStatusError = 'error';

class AiImageOcrTextResult {
  const AiImageOcrTextResult({
    required this.messageId,
    required this.conversationId,
    required this.engine,
    required this.status,
    required this.text,
    required this.cached,
    this.errorText,
    this.lines = const [],
  });

  final String messageId;
  final String conversationId;
  final String engine;
  final String status;
  final String text;
  final bool cached;
  final String? errorText;
  final List<Map<String, dynamic>> lines;

  bool get hasText => text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'conversation_id': conversationId,
    'engine': engine,
    'status': status,
    'cached': cached,
    'text': text,
    if (errorText?.isNotEmpty == true) 'error_text': errorText,
    if (lines.isNotEmpty) 'lines': lines,
  };

  List<String> toPromptLines(String title) => [
    title,
    'message_id=$messageId engine=$engine status=$status cached=$cached',
    if (status == _kOcrStatusDone) hasText ? text.trim() : 'no text recognized',
    if (status != _kOcrStatusDone)
      'unavailable: ${errorText ?? 'unknown error'}',
  ];
}

class AiImageOcrService {
  AiImageOcrService(this.database);

  final Database database;

  Future<AiImageOcrTextResult> recognizeMessageImageText({
    required String conversationId,
    required String messageId,
  }) async {
    final message = await database.messageDao
        .messageItemByMessageId(messageId)
        .getSingleOrNull();
    if (message == null) {
      return _unavailable(
        conversationId: conversationId,
        messageId: messageId,
        errorText: 'message not found',
      );
    }
    if (message.conversationId != conversationId) {
      return _unavailable(
        conversationId: conversationId,
        messageId: messageId,
        errorText: 'message is not in the current conversation',
      );
    }
    if (!message.type.isImage) {
      return _unavailable(
        conversationId: conversationId,
        messageId: messageId,
        errorText: 'message is not an image',
      );
    }

    final file = await _messageImageFile(message);
    if (file == null) {
      return _unavailable(
        conversationId: conversationId,
        messageId: messageId,
        errorText: 'local image file is not available',
      );
    }
    final fingerprint = await _mediaFingerprint(message, file);
    final cached = await database.aiImageOcrDao.resultByMessageId(messageId);
    if (cached != null &&
        cached.mediaFingerprint == fingerprint &&
        cached.engine == aiImageOcrEngine) {
      return _fromCache(cached);
    }

    try {
      final result = await _recognizeText(file);
      final text = result.text.trim();
      final lines = result.lines.map(_ocrLineToJson).toList(growable: false);
      await _saveResult(
        message: message,
        fingerprint: fingerprint,
        status: _kOcrStatusDone,
        text: text,
        lines: lines,
      );
      return AiImageOcrTextResult(
        messageId: messageId,
        conversationId: conversationId,
        engine: aiImageOcrEngine,
        status: _kOcrStatusDone,
        text: text,
        cached: false,
        lines: lines,
      );
    } catch (error, stacktrace) {
      e('AI image OCR failed: $error, $stacktrace');
      final errorText = error.toString();
      await _saveResult(
        message: message,
        fingerprint: fingerprint,
        status: _kOcrStatusError,
        text: '',
        errorText: errorText,
      );
      return _unavailable(
        conversationId: conversationId,
        messageId: messageId,
        errorText: errorText,
      );
    }
  }

  Future<File?> _messageImageFile(MessageItem message) async {
    final identityNumber = database.identityNumber;
    if (identityNumber == null || identityNumber.isEmpty) {
      return null;
    }
    final path = AttachmentUtilBase.of(identityNumber).convertAbsolutePath(
      category: message.type,
      conversationId: message.conversationId,
      fileName: message.mediaUrl,
    );
    if (path.isEmpty) {
      return null;
    }
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<String> _mediaFingerprint(MessageItem message, File file) async {
    final stat = file.statSync();
    return [
      message.mediaUrl ?? '',
      stat.size,
      stat.modified.toUtc().toIso8601String(),
    ].join('|');
  }

  Future<OcrResult> _recognizeText(File file) async {
    if (Platform.isMacOS || Platform.isIOS) {
      return _recognizeDarwinText(file);
    }
    final ocr = PlatformOcr();
    try {
      return await ocr.recognizeText(OcrSource.file(file));
    } finally {
      ocr.dispose();
    }
  }

  Future<void> _saveResult({
    required MessageItem message,
    required String fingerprint,
    required String status,
    required String text,
    List<Map<String, dynamic>> lines = const [],
    String? errorText,
  }) {
    final now = DateTime.now();
    return database.aiImageOcrDao.upsertResult(
      ImageOcrResultsCompanion.insert(
        messageId: message.messageId,
        conversationId: message.conversationId,
        mediaFingerprint: fingerprint,
        engine: aiImageOcrEngine,
        status: status,
        recognizedText: Value(text),
        linesJson: Value(lines.isEmpty ? null : jsonEncode(lines)),
        errorText: Value(errorText),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

Map<String, dynamic> _ocrLineToJson(OcrLine line) => {
  'text': line.text,
  'box': {
    'left': line.boundingBox.left,
    'top': line.boundingBox.top,
    'width': line.boundingBox.width,
    'height': line.boundingBox.height,
  },
};

Future<OcrResult> _recognizeDarwinText(File file) async =>
    pkg_ffi.using((arena) async {
      var result = OcrResult(text: '', lines: []);
      objc.autoReleasePool(() {
        final request = darwin.VNRecognizeTextRequest.alloc().init()
          ..recognitionLevel = darwin
              .VNRequestTextRecognitionLevel
              .VNRequestTextRecognitionLevelAccurate
          ..usesLanguageCorrection = true;
        _enableLanguageAutoDetection(request);

        final url = objc.NSURL.fileURLWithPath(objc.NSString(file.path));
        final handler = darwin.VNImageRequestHandler.alloc().initWithURL(
          url,
          options: objc.NSDictionary.new$(),
        );
        final success = handler.performRequests(
          objc.NSArray.arrayWithObject(request),
        );
        if (!success) {
          throw Exception('Vision request failed');
        }

        final resultsArr = request.results;
        if (resultsArr == null) {
          return;
        }
        final lines = <OcrLine>[];
        final fullTextBuffer = StringBuffer();
        for (var i = 0; i < resultsArr.count; i++) {
          final obj = resultsArr.objectAtIndex(i);
          if (!darwin.VNRecognizedTextObservation.isA(obj)) {
            continue;
          }
          final observation = darwin.VNRecognizedTextObservation.as(obj);
          final topCandidates = observation.topCandidates(1);
          if (topCandidates.count == 0) {
            continue;
          }
          final recognizedText = darwin.VNRecognizedText.as(
            topCandidates.objectAtIndex(0),
          );
          final text = recognizedText.string.toDartString();
          final box = observation.boundingBox;
          final rect = Rect.fromLTWH(
            box.origin.x,
            1.0 - box.origin.y - box.size.height,
            box.size.width,
            box.size.height,
          );
          lines.add(OcrLine(text: text, boundingBox: rect));
          fullTextBuffer.writeln(text);
        }
        result = OcrResult(
          text: fullTextBuffer.toString().trim(),
          lines: lines,
        );
      });
      return result;
    });

void _enableLanguageAutoDetection(darwin.VNRecognizeTextRequest request) {
  try {
    request.automaticallyDetectsLanguage = true;
  } catch (_) {
    // Available on newer Darwin versions only.
  }
}

AiImageOcrTextResult _fromCache(ImageOcrResult row) => AiImageOcrTextResult(
  messageId: row.messageId,
  conversationId: row.conversationId,
  engine: row.engine,
  status: row.status,
  text: row.recognizedText,
  cached: true,
  errorText: row.errorText,
  lines: _decodeLines(row.linesJson),
);

AiImageOcrTextResult _unavailable({
  required String conversationId,
  required String messageId,
  required String errorText,
}) => AiImageOcrTextResult(
  messageId: messageId,
  conversationId: conversationId,
  engine: aiImageOcrEngine,
  status: _kOcrStatusError,
  text: '',
  cached: false,
  errorText: errorText,
);

List<Map<String, dynamic>> _decodeLines(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const [];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
