import 'package:flutter/material.dart';

import '../../message_bubble.dart';

class InscriptionMessage extends StatelessWidget {
  const InscriptionMessage({super.key});

  @override
  Widget build(BuildContext context) => const MessageBubble(
        child: Text('test'),
      );
}
