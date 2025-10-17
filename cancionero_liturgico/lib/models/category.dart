class Category {
  final int? id;
  final String name;
  final String? color;
  final int order;
  final bool isPredefined;

  Category({
    this.id,
    required this.name,
    this.color,
    this.order = 0,
    this.isPredefined = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'color': color,
      'orden': order,
      'es_predefinida': isPredefined ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['nombre'] as String,
      color: map['color'] as String?,
      order: map['orden'] as int? ?? 0,
      isPredefined: (map['es_predefinida'] as int? ?? 0) == 1,
    );
  }
}