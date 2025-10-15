// ELIMINAR JSON SERIALIZATION TEMPORALMENTE
class Category {
  final int? id;
  final String name;
  final String color;
  final int order;
  final bool isPredefined;

  Category({
    this.id,
    required this.name,
    this.color = "#4CAF50",
    this.order = 0,
    this.isPredefined = false,
  });

  // Convertir a Map para la base de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'order_index': order,
      'is_predefined': isPredefined ? 1 : 0,
    };
  }

  // Crear desde Map
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? "#4CAF50",
      order: json['order_index'] ?? 0,
      isPredefined: json['is_predefined'] == 1,
    );
  }
}