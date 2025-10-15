import 'package:json_annotation/json_annotation.dart';
import 'cancion_model.dart'; // Mantener español existente
import 'category_model.dart'; // Nuevo en inglés

part 'setlist_model.g.dart';

@JsonSerializable()
class Setlist {
  final int? id;
  final String nombre;
  final DateTime? fechaEvento;
  final String? notas;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;

  Setlist({
    this.id,
    required this.nombre,
    this.fechaEvento,
    this.notas,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  factory Setlist.fromJson(Map<String, dynamic> json) =>
      _$SetlistFromJson(json);
  Map<String, dynamic> toJson() => _$SetlistToJson(this);
}

@JsonSerializable()
class SetlistCancion {
  final int? id;
  final int setlistId;
  final int cancionId;
  final int orden;
  final int transposicionSemitonos;
  final int? capoPersonalizado;
  final Cancion? cancion; // Joined data

  SetlistCancion({
    this.id,
    required this.setlistId,
    required this.cancionId,
    required this.orden,
    this.transposicionSemitonos = 0,
    this.capoPersonalizado,
    this.cancion,
  });

  factory SetlistCancion.fromJson(Map<String, dynamic> json) =>
      _$SetlistCancionFromJson(json);
  Map<String, dynamic> toJson() => _$SetlistCancionToJson(this);
}