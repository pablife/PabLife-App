import 'dart:convert';

class OnboardingModel {
  final int id;
  final String title;
  final String description;
  final String imagePath;
  final bool isLastPage;

  OnboardingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLastPage = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'isLastPage': isLastPage,
    };
  }

  factory OnboardingModel.fromMap(Map<String, dynamic> map) {
    return OnboardingModel(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      isLastPage: map['isLastPage'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory OnboardingModel.fromJson(String source) =>
      OnboardingModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
