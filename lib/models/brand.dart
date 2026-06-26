class Brand {
  final String id;
  final String name;
  final String description;

  const Brand({required this.id, required this.name, this.description = ''});

  factory Brand.fromFirestore(String id, Map<String, dynamic> data) => Brand(
    id: id, name: data['name'] as String? ?? '', description: data['description'] as String? ?? '',
  );

  Map<String, dynamic> toFirestore() => {'name': name, 'description': description};
}
