class Category {
  final int? id;
  final String name;
  final String? color; // Nuevo campo
  final int order;     // Nuevo campo, con valor por defecto
  final bool isPredefined; // Nuevo campo, con valor por defecto

  Category({
    this.id,
    required this.name,
    this.color,           // Puede ser nulo
    this.order = 0,       // Valor por defecto
    this.isPredefined = false, // Valor por defecto
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'order': order,
      'is_predefined': isPredefined ? 1 : 0, // SQLite no tiene booleano nativo
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] as String,
      color: map['color'] as String?,
      order: map['order'] as int? ?? 0,
      isPredefined: (map['is_predefined'] as int? ?? 0) == 1,
    );
  }
}