import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/utils/group_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  Future<img.Image> encode(int width, int height) async {
    final dir = await Directory.systemTemp.createTemp('group_photo_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File(
      '${dir.path}/photo.png',
    )..writeAsBytesSync(img.encodePng(img.Image(width: width, height: height)));

    final iconBase64 = (await encodeGroupPhoto(file.path))!;
    expect(iconBase64, isNot(matches(RegExp('[=+/]'))));
    final bytes = base64Url.decode(base64Url.normalize(iconBase64));
    expect(img.JpegDecoder().isValidFile(bytes), isTrue);
    return img.decodeJpg(bytes)!;
  }

  test('a large photo becomes a 512 px square', () async {
    final photo = await encode(800, 600);
    expect((photo.width, photo.height), (512, 512));
  });

  test('a small photo is cropped to a square but not scaled up', () async {
    final photo = await encode(100, 50);
    expect((photo.width, photo.height), (50, 50));
  });

  test('a file that is not an image gives null', () async {
    final dir = await Directory.systemTemp.createTemp('group_photo_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/photo.png')..writeAsStringSync('text');
    expect(await encodeGroupPhoto(file.path), isNull);
  });
}
