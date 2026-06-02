import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../models/local_track.dart';

class LyricsService {
  LyricsService._();

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://api.lrc.cx',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        )
        ..interceptors.add(
          DioCacheInterceptor(
            options: CacheOptions(
              store: MemCacheStore(),
              policy: CachePolicy.forceCache,
              hitCacheOnNetworkFailure: true,
              maxStale: const Duration(days: 30),
            ),
          ),
        );

  static Future<String?> fetchLyrics(LocalTrack track) async {
    try {
      final params = <String, dynamic>{'title': track.title};
      if (track.artist.isNotEmpty) {
        params['artist'] = track.artist;
      }
      if (track.album.isNotEmpty && track.album != '[Unknown Album]') {
        params['album'] = track.album;
      }
      params['path'] = track.filePath;

      final res = await _dio.get('/lyrics', queryParameters: params);
      if (res.statusCode == 200 && res.data is String) {
        final text = res.data as String;
        if (text.trim().isNotEmpty) return text;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
