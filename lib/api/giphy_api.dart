import 'package:dio/dio.dart';

import 'giphy_vo/giphy_result_data.dart';

const _giphyUrl = 'https://api.giphy.com/v1/';
const _giphyApiKey = 'n4E08oEoAWFCipgPMbERwXs4sAMEGaSc';

class GiphyApi {
  GiphyApi(this.dio);

  static GiphyApi instance = GiphyApi(Dio(BaseOptions(
    baseUrl: _giphyUrl,
  )));

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
