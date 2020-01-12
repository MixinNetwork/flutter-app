import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

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
    final keypair = x25519.newKeyPair();
    var pubKey = Uri.encodeComponent(keypair.publicKey.toBase64());

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
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
              data: "mixin://device/auth?id="+uuid + "&pub_key=" + pubKey,
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
