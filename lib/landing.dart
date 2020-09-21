import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class LandingPage extends StatefulWidget {
  LandingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    var deviceId = Uuid().v4();
    final keypair = x25519.newKeyPairSync();
    var pubKey = Uri.encodeComponent(base64.encode(keypair.publicKey.bytes));

    Timer.periodic(Duration(seconds: 2), (timer) {
      // fetch
      timer.cancel();
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Open Mixin Messenger on your phone, capture the code',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(
              height: 30,
            ),
            QrImage(
              data: "mixin://device/auth?id=" + deviceId + "&pub_key=" + pubKey,
              version: QrVersions.auto,
              size: 300.0,
              foregroundColor: Color(0xFF4A4A4A),
              embeddedImage: AssetImage('assets/images/logo.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size(60, 60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
