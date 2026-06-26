import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageSearchResult {
  final String thumbnail;
  final String fullUrl;
  final String tags;

  ImageSearchResult({
    required this.thumbnail,
    required this.fullUrl,
    required this.tags,
  });
}

class ImageSearchService {
  static const String _baseUrl = 'https://pixabay.com/api/';
  static const String _apiKey = '46458087-d0f495c0a0e0c12f36e3d9ec6';

  Future<List<ImageSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl?key=$_apiKey&q=${Uri.encodeComponent(query)}&image_type=photo&per_page=12&safesearch=true'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final hits = data['hits'] as List<dynamic>? ?? [];
      return hits.map((h) => ImageSearchResult(
        thumbnail: h['previewURL'] as String? ?? '',
        fullUrl: h['largeImageURL'] as String? ?? '',
        tags: h['tags'] as String? ?? '',
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
