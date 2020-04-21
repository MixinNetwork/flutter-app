import 'package:http/http.dart' as http;
import 'client.dart';

class BaseAPI {
  var client = BearerClient("", "", http.Client());
}
