import 'package:flutter/widgets.dart';

/// Names the recipient of a send confirmation: the name and Mixin ID, or the
/// raw id when the user is not known yet. Only the name is truncated, so a
/// long name cannot push the real Mixin ID out of view.
class SendRecipientLabel extends StatelessWidget {
  const SendRecipientLabel({
    required this.userId,
    required this.style,
    this.fullName,
    this.identityNumber,
    super.key,
  });

  final String userId;
  final String? fullName;
  final String? identityNumber;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final name = (fullName ?? '').trim();
    final id = identityNumber ?? '';
    if (name.isEmpty && id.isEmpty) {
      return Text(
        userId,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name.isNotEmpty)
          Flexible(
            child: Text(
              name,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (id.isNotEmpty)
          Text(name.isEmpty ? id : ' ($id)', style: style, maxLines: 1),
      ],
    );
  }
}
