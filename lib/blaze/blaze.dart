import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class Blaze {
  void connect(String token) {
    final channel = IOWebSocketChannel.connect(
        'wss://blaze.mixin.one?access_token=$token',
        protocols: ['Mixin-Blaze-1']);
    ;
    debugPrint('wss://blaze.mixin.one?access_token=$token');
    channel.stream.listen((message) {
      debugPrint(String.fromCharCodes(GZipDecoder().decodeBytes(message)));
    }, onError: (error) {
      debugPrint('onError');
    }, onDone: () {
      debugPrint('onDone');
    }, cancelOnError: true);

    channel.sink.add('test');
  }
}
