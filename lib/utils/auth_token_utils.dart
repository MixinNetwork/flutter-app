import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const kAuthTokenDelayThreshold = Duration(seconds: 60);

DateTime? bearerTokenIssuedAt(String? authorizationHeader) {
  final token = _extractBearerToken(authorizationHeader);
  if (token == null) return null;

  try {
    final jwt = JWT.tryDecode(token);
    final payload = jwt?.payload;
    if (payload is! Map) return null;

    final iat = _parseIssuedAt(payload['iat']);
    if (iat == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true);
  } on JWTException {
    return null;
  }
}

int? _parseIssuedAt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool isBearerTokenDelayed(
  String? authorizationHeader, {
  DateTime? now,
  Duration threshold = kAuthTokenDelayThreshold,
}) {
  final issuedAt = bearerTokenIssuedAt(authorizationHeader);
  if (issuedAt == null) return false;

  final currentTime = (now ?? DateTime.now()).toUtc();
  return currentTime.difference(issuedAt).abs() > threshold;
}

String? _extractBearerToken(String? authorizationHeader) {
  if (authorizationHeader == null) return null;
  final header = authorizationHeader.trim();
  if (header.isEmpty) return null;

  const prefix = 'Bearer ';
  if (!header.startsWith(prefix)) return null;
  final token = header.substring(prefix.length).trim();
  return token.isEmpty ? null : token;
}
