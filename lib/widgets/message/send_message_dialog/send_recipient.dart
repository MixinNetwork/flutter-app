/// How the send confirmation names the recipient: the name and Mixin ID, or the raw id when the user is not known yet.
String recipientLine({
  required String userId,
  String? fullName,
  String? identityNumber,
}) {
  final name = (fullName ?? '').trim();
  final id = identityNumber ?? '';
  if (name.isEmpty && id.isEmpty) return userId;
  if (id.isEmpty) return name;
  if (name.isEmpty) return id;
  return '$name ($id)';
}
