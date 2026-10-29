class MentoriaCategoryModel {
  final String id;
  final String name;

  MentoriaCategoryModel({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'name': name};
  }

  factory MentoriaCategoryModel.fromMap(Map<String, dynamic> map) {
    return MentoriaCategoryModel(id: map['id'] ?? '', name: map['name'] ?? '');
  }
}
