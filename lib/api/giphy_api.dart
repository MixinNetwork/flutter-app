import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import 'giphy_vo/giphy_result_data.dart';

const _giphyUrl = 'https://api.giphy.com/v1/';

class GiphyApi {
  GiphyApi(this.dio);

  static GiphyApi instance = GiphyApi(
    Dio(
        BaseOptions(
          baseUrl: _giphyUrl,
          contentType: 'application/json; charset=utf-8',
        ),
      )
      ..interceptors.addAll([
        if (!kReleaseMode) MixinLogInterceptor(HttpLogLevel.none),
      ]),
  );

  final Dio dio;

  Future<GiphyResultData> trendingGifs(int limit, int offset) async {
    final response = await dio.get<Map<String, dynamic>>(
      'gifs/trending',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'api_key': giphyApiKey,
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
        'api_key': giphyApiKey,
      },
    );
    return GiphyResultData.fromJson(response.data!);
  }
}
