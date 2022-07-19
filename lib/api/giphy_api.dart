import 'package:dio/dio.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'giphy_vo/giphy_result_data.dart';

const _giphyUrl = 'https://api.giphy.com/v1/';
const _giphyApiKey = '';

class GiphyApi {
  GiphyApi(this.dio);

  static GiphyApi instance = GiphyApi(
    Dio(BaseOptions(baseUrl: _giphyUrl))
      ..interceptors.add(MixinLogInterceptor(HttpLogLevel.all)),
  );

  final Dio dio;

  Future<GiphyResultData> trendingGifs(int limit, int offset) async {
    final response = await dio.get<Map<String, dynamic>>(
      'gifs/trending',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'api_key': _giphyApiKey,
      },
    );
    return GiphyResultData.fromJson(response.data!);
  }

  Future<GiphyResultData> search(String query, int limit, int offset) async {
    final response = await dio.get<Map<String, dynamic>>(
      'gifs/search',
      queryParameters: {
        'q': query,
        'limit': limit,
        'offset': offset,
        'api_key': _giphyApiKey,
      },
    );
    return GiphyResultData.fromJson(response.data!);
  }
}
