import 'package:http/http.dart' as http;

class BearerClient extends http.BaseClient {
  final String userId;
  final http.Client _inner;

  BearerClient(this.userId, this._inner);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = 'Mixin/0.0.1 Flutter';
    request.headers['Accept-Language'] = 'en';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ';
    return _inner.send(request);
  }
}