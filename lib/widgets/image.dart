import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ImageByBase64 extends HookWidget {
  const ImageByBase64(
    this.base64String, {
    Key? key,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  final String base64String;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final bytes = useMemoized(() => base64Decode(base64String), [base64String]);
    return Image.memory(
      bytes,
      fit: fit,
    );
  }
}
