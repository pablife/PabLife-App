import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  static YoutubeService? _instance;
  static YoutubeService get instance => _instance ??= YoutubeService._();

  YoutubeService._();

  final YoutubeExplode _yt = YoutubeExplode();

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }

    if (uri.host.contains('youtube.com')) {
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  Future<YoutubeVideoInfo?> getVideoInfo(String videoUrl) async {
    try {
      final videoId = _extractYoutubeId(videoUrl);
      if (videoId == null) {
        debugPrint('[YoutubeService] URL inválida: $videoUrl');
        return null;
      }

      // No navegador o youtube_explode é bloqueado por CORS; o oEmbed não.
      if (kIsWeb) return _getVideoInfoWeb(videoUrl, videoId);

      debugPrint('[YoutubeService] Buscando informações do vídeo: $videoId');
      final video = await _yt.videos.get(videoId);

      final thumbnails = video.thumbnails;
      final thumbnailUrl = thumbnails.highResUrl.isNotEmpty
          ? thumbnails.highResUrl
          : thumbnails.mediumResUrl.isNotEmpty
          ? thumbnails.mediumResUrl
          : thumbnails.standardResUrl.isNotEmpty
          ? thumbnails.standardResUrl
          : thumbnails.maxResUrl.isNotEmpty
          ? thumbnails.maxResUrl
          : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

      debugPrint('[YoutubeService] Thumbnail encontrada: $thumbnailUrl');
      debugPrint('[YoutubeService] Título: ${video.title}');

      return YoutubeVideoInfo(
        title: video.title,
        thumbnailUrl: thumbnailUrl,
        duration: video.duration ?? Duration.zero,
      );
    } catch (e) {
      debugPrint('[YoutubeService] Erro ao buscar informações: $e');
      return null;
    }
  }

  Future<YoutubeVideoInfo?> _getVideoInfoWeb(
    String videoUrl,
    String videoId,
  ) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': 'https://www.youtube.com/watch?v=$videoId',
      'format': 'json',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('[YoutubeService] oEmbed falhou (${response.statusCode}): $videoUrl');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return YoutubeVideoInfo(
      title: data['title'] as String? ?? '',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      duration: Duration.zero,
    );
  }

  Future<List<YoutubeVideoInfo>> getVideosInfo(List<String> videoUrls) async {
    final results = <YoutubeVideoInfo>[];

    for (final url in videoUrls) {
      final info = await getVideoInfo(url);
      if (info != null) {
        results.add(info);
      }
    }

    return results;
  }

  void dispose() {
    _yt.close();
  }
}

class YoutubeVideoInfo {
  final String title;
  final String thumbnailUrl;
  final Duration duration;

  YoutubeVideoInfo({
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
  });

  int get durationSeconds => duration.inSeconds;
}
