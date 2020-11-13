import 'dart:async';

import 'package:bot_api_dart_client/bot_api_dart_client.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../../mixin_client.dart';

class LandingPage extends StatefulWidget {
  LandingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _showRetry = false;
  bool _provisioning = true;
  String _authUrl;
  Timer _timer;
  void showRetryTask(String deviceId) {
    int count = 1;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (count >= 60) {
        timer.cancel();
        setState(() {
          this._showRetry = true;
        });
      } else {
        count++;
        MixinClient()
            .client
            .provisioningApi
            .getProvisioning(deviceId)
            .then((response) => {
                  response.data.handleResponse<Provisioning>(
                      onSuccess: (Provisioning provisioning) {
                        if (provisioning.secret?.isNotEmpty == true) {
                          _timer?.cancel();
                          // Todo
                          setState(() {
                            this._provisioning = true;
                          });
                          print(provisioning.secret);
                        }
                      },
                      onFailure: (MixinError error) =>
                          {print(error.toString())})
                });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    generateAuthUrl();
  }

  void generateAuthUrl() {
    MixinClient()
        .client
        .provisioningApi
        .getProvisioningId(Platform.operatingSystem)
        .then((response) {
      response.data.handleResponse<Provisioning>(
          onSuccess: (Provisioning provisioning) {
        setState(() {
          final keypair = signal.Curve.generateKeyPair();
          var pubKey =
              Uri.encodeComponent(base64.encode(keypair.publicKey.serialize()));
          this._authUrl =
              "mixin://device/auth?id=${provisioning.deviceId}&pub_key=$pubKey";
          this._provisioning = false;
        });
        showRetryTask(provisioning.deviceId);
      }, onFailure: (MixinError error) {
        print(error.toJson());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Visibility(
                  visible: this._authUrl != null,
                  child: QrImage(
                    data: this._authUrl,
                    version: QrVersions.auto,
                    size: 300.0,
                    foregroundColor: Color(0xFF4A4A4A),
                    embeddedImage: AssetImage('assets/images/logo.png'),
                    embeddedImageStyle: QrEmbeddedImageStyle(
                      size: Size(60, 60),
                    ),
                  )),
              Visibility(
                  visible: _showRetry || _provisioning,
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          this._showRetry = false;
                          generateAuthUrl();
                        });
                      },
                      child: Container(
                          width: 300.0,
                          height: 300.0,
                          decoration:
                              new BoxDecoration(color: Color(0xAAFFFFFF)),
                          child: Align(
                              alignment: Alignment.center,
                              child: _buildCoverWidget()))))
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverWidget() {
    if (_provisioning) {
      return SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ));
    } else if (_showRetry) {
      return Container(
          constraints: BoxConstraints.tightForFinite(width: 150, height: 150),
          alignment: Alignment.center,
          decoration: new BoxDecoration(
              color: Color(0xFF3a7ee4),
              borderRadius: BorderRadius.circular(75)),
          child: Padding(
            padding: EdgeInsets.all(0.0),
            child: Text("点击重试",
                style: TextStyle(fontSize: 14.0, color: Colors.white)),
          ));
    } else {
      return Container();
    }
  }
}
