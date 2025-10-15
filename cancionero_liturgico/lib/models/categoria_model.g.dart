// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Categoria _$CategoriaFromJson(Map<String, dynamic> json) => Categoria(
  id: (json['id'] as num?)?.toInt(),
  nombre: json['nombre'] as String,
  color: json['color'] as String? ?? "#4CAF50",
  orden: (json['orden'] as num?)?.toInt() ?? 0,
  esPredefinida: json['esPredefinida'] as bool? ?? false,
);

Map<String, dynamic> _$CategoriaToJson(Categoria instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'color': instance.color,
  'orden': instance.orden,
  'esPredefinida': instance.esPredefinida,
};
