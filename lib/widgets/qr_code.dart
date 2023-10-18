import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrCode extends StatelessWidget {
  const QrCode({
    super.key,
    required this.data,
    this.image,
    this.dimension,
  });

  final String data;
  final ImageProvider? image;
  final double? dimension;

  @override
  Widget build(BuildContext context) => Container(
        width: dimension,
        height: dimension,
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: PrettyQrView.data(
          decoration: PrettyQrDecoration(
            image:
                image == null ? null : PrettyQrDecorationImage(image: image!),
          ),
          data: data,
        ),
      );
}
