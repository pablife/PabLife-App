class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      imageUrl: map['image_url'] ?? '',
      linkUrl: map['redirect_url'] ?? '',
      isActive: map['is_active'] == true,
      startDate: null,
      endDate: map['expiration_at'] != null
          ? DateTime.parse(map['expiration_at'])
          : null,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'title': title,
    'image_url': imageUrl,
    'redirect_url': linkUrl,
    'is_active': isActive,
    if (endDate != null) 'expiration_at': endDate!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}
