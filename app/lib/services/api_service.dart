import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class ApiService {
  ApiService._();

  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<List<Track>> fetchTracks() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/tracks'));
    if (res.statusCode != 200) {
      throw HttpException('Failed to fetch tracks: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Track> uploadTrack({
    required String title,
    required String artist,
    required String filePath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/upload'),
    );
    req.fields['title'] = title;
    req.fields['artist'] = artist;
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw HttpException('Failed to upload track: ${res.statusCode}');
    }
    return Track.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
