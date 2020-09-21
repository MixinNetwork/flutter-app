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
  bool _showRetry = false;

  void showRetryTask() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        this._showRetry = true;
      });
      timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    var deviceId = Uuid().v4();
    final keypair = x25519.newKeyPairSync();
    var pubKey = Uri.encodeComponent(base64.encode(keypair.publicKey.bytes));
    showRetryTask();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Open Mixin Messenger on your phone, capture the code',
                style: TextStyle(fontSize: 18.0), textAlign: TextAlign.center),
            SizedBox(
              height: 30,
            ),
            Stack(alignment: AlignmentDirectional.center, children: [
              QrImage(
                data:
                    "mixin://device/auth?id=" + deviceId + "&pub_key=" + pubKey,
                version: QrVersions.auto,
                size: 300.0,
                foregroundColor: Color(0xFF4A4A4A),
                embeddedImage: AssetImage('assets/images/logo.png'),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(60, 60),
                ),
              ),
              Visibility(
                  visible: _showRetry,
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          this._showRetry = false;
                          showRetryTask();
                        });
                      },
                      child: Container(
                        width: 300.0,
                        height: 300.0,
                        decoration: new BoxDecoration(color: Color(0xAAFFFFFF)),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                              constraints: BoxConstraints.tightForFinite(
                                  width: 150, height: 150),
                              alignment: Alignment.center,
                              decoration: new BoxDecoration(
                                  color: Color(0xFF3a7ee4),
                                  borderRadius: BorderRadius.circular(75)),
                              child: Padding(
                                padding: EdgeInsets.all(0.0),
                                child: Text("点击重试",
                                    style: TextStyle(
                                        fontSize: 14.0, color: Colors.white)),
                              )),
                        ),
                      )))
            ]),
          ],
        ),
      ),
    );
  }
}
