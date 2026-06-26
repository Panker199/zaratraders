class Unit {
  final String id;
  final String name;
  final String shortName;

  const Unit({required this.id, required this.name, required this.shortName});

  factory Unit.fromFirestore(String id, Map<String, dynamic> data) => Unit(
    id: id, name: data['name'] as String? ?? '', shortName: data['shortName'] as String? ?? '',
  );

  Map<String, dynamic> toFirestore() => {'name': name, 'shortName': shortName};
}
