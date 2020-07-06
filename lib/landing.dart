import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class LandingPage extends StatefulWidget {
  LandingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    var uuid = Uuid().v4();
    final keypair = x25519.newKeyPairSync();
    var pubKey = Uri.encodeComponent(base64.encode(keypair.publicKey.bytes));

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
              data: "mixin://device/auth?id=" + uuid + "&pub_key=" + pubKey,
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
