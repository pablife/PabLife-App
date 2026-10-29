import 'dart:convert';

class MentorshipModel {
  final String id;
  final String title;
  final String author;
  final int duration; // integer no banco
  final String description;
  final String categoryId;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? categoryName; // nome da categoria via join

  MentorshipModel({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.description,
    required this.categoryId,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.categoryName,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'author': author,
      'duration': duration,
      'description': description,
      'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory MentorshipModel.fromMap(Map<String, dynamic> map) {
    return MentorshipModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      duration: map['duration'] is int
          ? map['duration']
          : int.tryParse('${map['duration']}') ?? 0,
      description: map['description'] ?? '',
      categoryId: map['category_id'] ?? '',
      imageUrl: map['image_url'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      categoryName: map['category_name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MentorshipModel.fromJson(String source) =>
      MentorshipModel.fromMap(json.decode(source) as Map<String, dynamic>);

  MentorshipModel copyWith({
    String? id,
    String? title,
    String? author,
    int? duration,
    String? description,
    String? categoryId,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? categoryName,
  }) {
    return MentorshipModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}

class MentorshipCategoryModel {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MentorshipCategoryModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory MentorshipCategoryModel.fromMap(Map<String, dynamic> map) {
    return MentorshipCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MentorshipCategoryModel.fromJson(String source) =>
      MentorshipCategoryModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

class MentorshipModuleModel {
  final String id;
  final String mentoringId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  MentorshipModuleModel({
    required this.id,
    required this.mentoringId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory MentorshipModuleModel.fromMap(Map<String, dynamic> map) {
    return MentorshipModuleModel(
      id: map['id'] ?? '',
      mentoringId: map['mentoring_id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mentoring_id': mentoringId,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };
}

class ModuleLessonModel {
  final String id;
  final String mentoringModuleId;
  final int lessonNumber;
  final String title;
  final String videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ModuleLessonModel({
    required this.id,
    required this.mentoringModuleId,
    required this.lessonNumber,
    required this.title,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ModuleLessonModel.fromMap(Map<String, dynamic> map) {
    return ModuleLessonModel(
      id: map['id'] ?? '',
      mentoringModuleId: map['mentoring_module_id'] ?? '',
      lessonNumber: map['lesson_number'] is int
          ? map['lesson_number']
          : int.tryParse('${map['lesson_number']}') ?? 0,
      title: map['title'] ?? '',
      videoUrl: map['video_url'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mentoring_module_id': mentoringModuleId,
    'lesson_number': lessonNumber,
    'title': title,
    'video_url': videoUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };
}

class FavoriteMentorshipModel {
  final String id;
  final String userId;
  final String mentorshipId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteMentorshipModel({
    required this.id,
    required this.userId,
    required this.mentorshipId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteMentorshipModel.fromMap(Map<String, dynamic> map) {
    return FavoriteMentorshipModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      mentorshipId: map['mentorship_id'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'mentorship_id': mentorshipId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
