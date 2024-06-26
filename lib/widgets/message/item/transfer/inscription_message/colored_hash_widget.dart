import '../../../../../utils/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class ColoredHashWidget extends HookWidget {
  const ColoredHashWidget({
    required this.inscriptionHex,
    this.blockSize = const Size(5, 16),
    this.space = 3,
    super.key,
  });

  final String? inscriptionHex;

  final Size blockSize;
  final double space;

  @override
  Widget build(BuildContext context) {
    final colors = useMemoized(() {
      if (inscriptionHex == null) {
        return List.filled(12, Colors.black12);
      }
      final bytes = inscriptionHex!.hexToBytes();
      final data = bytes + sha3Hash(bytes).sublist(0, 4);
      final colors = <Color>[];
      for (var i = 0; i < data.length; i += 3) {
        colors.add(Color.fromARGB(0xFF, data[i], data[i + 1], data[i + 2]));
      }
      return colors;
    }, [inscriptionHex]);
    return Row(
      children: <Widget>[
        for (final color in colors)
          Container(
            width: blockSize.width,
            height: blockSize.height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ].joinList(SizedBox(width: space)),
    );
  }
}
