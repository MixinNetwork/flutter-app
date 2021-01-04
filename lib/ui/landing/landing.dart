import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../mixin_client.dart';
import 'loading.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _showRetry = false;
  bool _provisioning = true;
  String _authUrl;
  Timer _timer;
  signal.ECKeyPair keyPair;

  void showRetryTask(String deviceId) {
    var count = 1;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (count >= 60) {
        timer.cancel();
        setState(() {
          _showRetry = true;
        });
      } else {
        count++;
        MixinClient()
            .client
            .provisioningApi
            .getProvisioning(deviceId)
            .then((response) => {
                  response.handleResponse(
                      onSuccess: (Provisioning provisioning) {
                        if (provisioning.secret?.isNotEmpty == true) {
                          _timer?.cancel();
                          setState(() {
                            _provisioning = true;
                          });
                          //decrypt
                          final result = signal.decrypt(
                              base64.encode(keyPair.privateKey.serialize()),
                              provisioning.secret);
                          final msg = json.decode(String.fromCharCodes(result));

                          final registrationId =
                              signal.KeyHelper.generateRegistrationId(false);
                          verify(ProvisioningRequest(
                              code: msg['provisioning_code'],
                              userId: msg['user_id'],
                              sessionId: msg['session_id'],
                              platform: 'Desktop',
                              purpose: 'SESSION',
                              sessionSecret: base64.encode(
                                  (keyPair.publicKey as DjbECPublicKey)
                                      .publicKey),
                              appVersion: '0.0.1',
                              registrationId: registrationId,
                              platformVersion: 'OS X 10.15.6'));
                        }
                      },
                      onFailure: (MixinError error) =>
                          {debugPrint(error.toString())})
                });
      }
    });
  }

  void verify(ProvisioningRequest request) {
    MixinClient()
        .client
        .provisioningApi
        .verifyProvisioning(request)
        .then((value) => {debugPrint('$value')}); //Todo
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoadingPage()),
    );
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
      response.handleResponse(onSuccess: (Provisioning provisioning) {
        setState(() {
          keyPair = signal.Curve.generateKeyPair();
          final pubKey =
              Uri.encodeComponent(base64.encode(keyPair.publicKey.serialize()));
          _authUrl =
              'mixin://device/auth?id=${provisioning.deviceId}&pub_key=$pubKey';
          _provisioning = false;
        });
        showRetryTask(provisioning.deviceId);
      }, onFailure: (MixinError error) {
        debugPrint('${error.toJson()}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Open Mixin Messenger on your phone, capture the code',
                style: TextStyle(fontSize: 18.0), textAlign: TextAlign.center),
            const SizedBox(
              height: 30,
            ),
            Stack(alignment: AlignmentDirectional.center, children: [
              Visibility(
                  visible: _authUrl != null,
                  child: QrImage(
                    data: _authUrl,
                    version: QrVersions.auto,
                    size: 300.0,
                    foregroundColor: const Color(0xFF4A4A4A),
                    embeddedImage: const AssetImage('assets/images/logo.png'),
                    embeddedImageStyle: QrEmbeddedImageStyle(
                      size: const Size(60, 60),
                    ),
                  )),
              Visibility(
                  visible: _showRetry || _provisioning,
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          _showRetry = false;
                          generateAuthUrl();
                        });
                      },
                      child: Container(
                          width: 300.0,
                          height: 300.0,
                          decoration:
                              const BoxDecoration(color: Color(0xAAFFFFFF)),
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
      return const SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ));
    } else if (_showRetry) {
      return Container(
          constraints:
              const BoxConstraints.tightForFinite(width: 150, height: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xFF3a7ee4),
              borderRadius: BorderRadius.circular(75)),
          child: const Padding(
            padding: EdgeInsets.all(0.0),
            child: Text('点击重试',
                style: TextStyle(fontSize: 14.0, color: Colors.white)),
          ));
    } else {
      return Container();
    }
  }
}
