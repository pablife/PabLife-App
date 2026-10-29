import 'dart:convert';

class MentoriaVideoModel {
  final String id;
  final String moduleId;
  final String title;
  final String videoUrl; // URL do player (YouTube, Vimeo, etc)
  final int lessonNumber;
  final int durationSeconds;
  final bool isWatched;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? thumbnailUrl;

  MentoriaVideoModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.videoUrl,
    required this.lessonNumber,
    this.durationSeconds = 0,
    this.isWatched = false,
    required this.createdAt,
    this.updatedAt,
    this.thumbnailUrl,
  });

  String get formattedDuration {
    if (durationSeconds <= 0) {
      return '--:--';
    }
    final minutes = (durationSeconds / 60).floor();
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get resolvedThumbnailUrl {
    if (thumbnailUrl?.isNotEmpty == true) {
      return thumbnailUrl!;
    }

    final youtubeId = _extractYoutubeId(videoUrl);
    if (youtubeId != null) {
      return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
    }

    return defaultMentoriaVideoThumbnail;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'module_id': moduleId,
      'title': title,
      'video_url': videoUrl,
      'lesson_number': lessonNumber,
      'duration_seconds': durationSeconds,
      'is_watched': isWatched,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
    };
  }

  factory MentoriaVideoModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return MentoriaVideoModel(
      id: map['id']?.toString() ?? '',
      moduleId:
          map['module_id']?.toString() ??
          map['mentoring_module_id']?.toString() ??
          '',
      title: map['title']?.toString() ?? '',
      videoUrl: map['video_url']?.toString() ?? '',
      lessonNumber:
          (map['lesson_number'] as num?)?.toInt() ?? map['order'] as int? ?? 0,
      durationSeconds:
          (map['duration_seconds'] as num?)?.toInt() ??
          (map['durationSeconds'] as num?)?.toInt() ??
          0,
      isWatched: map['is_watched'] == true || map['isWatched'] == true,
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: parseNullableDate(map['updated_at'] ?? map['updatedAt']),
      thumbnailUrl:
          map['thumbnail_url']?.toString() ?? map['thumbnailUrl']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MentoriaVideoModel.fromJson(String source) =>
      MentoriaVideoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  MentoriaVideoModel copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? videoUrl,
    int? lessonNumber,
    int? durationSeconds,
    bool? isWatched,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailUrl,
  }) {
    return MentoriaVideoModel(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isWatched: isWatched ?? this.isWatched,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

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

const String defaultMentoriaVideoThumbnail =
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80';
