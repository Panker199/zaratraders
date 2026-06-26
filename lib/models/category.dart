class Category {
  final String id;
  final String name;
  final String description;
  final List<String> subCategories;

  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.subCategories = const [],
  });

  factory Category.fromJson(String id, Map<String, dynamic> json) {
    final raw = json['subCategories'];
    final List<String> subCats;
    if (raw is List) {
      subCats = raw.map((e) => e.toString()).toList();
    } else {
      subCats = const [];
    }
    return Category(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      subCategories: subCats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (subCategories.isNotEmpty) 'subCategories': subCategories,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? subCategories,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subCategories: subCategories ?? this.subCategories,
    );
  }
}
