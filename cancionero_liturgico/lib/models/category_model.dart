import 'package:json_annotation/json_annotation.dart';

part 'categoria_model.g.dart';

@JsonSerializable()
class Categoria {
  final int? id;
  final String nombre;
  final String color;
  final int orden;
  final bool esPredefinida;

  Categoria({
    this.id,
    required this.nombre,
    this.color = "#4CAF50",
    this.orden = 0,
    this.esPredefinida = false,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) =>
      _$CategoriaFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriaToJson(this);

  @override
  String toString() {
    return 'Categoria{id: $id, nombre: $nombre, color: $color}';
  }
}