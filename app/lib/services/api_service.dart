import 'package:dio/dio.dart';
import '../models/track.dart';

class ApiService {
  ApiService._();

  static late Dio _dio;

  static void init({String baseUrl = 'http://10.0.2.2:3000'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  static void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  static Future<List<Track>> fetchTracks() async {
    final res = await _dio.get('/api/tracks');
    final list = res.data as List;
    return list.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Track> uploadTrack({
    required String title,
    required String artist,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'artist': artist,
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/api/upload', data: formData);
    return Track.fromJson(res.data as Map<String, dynamic>);
  }
}
