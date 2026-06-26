class Warehouse {
  final String id;
  final String name;
  final String location;
  final String description;

  const Warehouse({required this.id, required this.name, this.location = '', this.description = ''});

  factory Warehouse.fromFirestore(String id, Map<String, dynamic> data) => Warehouse(
    id: id,
    name: data['name'] as String? ?? '',
    location: data['location'] as String? ?? '',
    description: data['description'] as String? ?? '',
  );

  Map<String, dynamic> toFirestore() => {'name': name, 'location': location, 'description': description};
}
