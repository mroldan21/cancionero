import 'package:json_annotation/json_annotation.dart';
import 'cancion_model.dart';

part 'setlist_model.g.dart';

@JsonSerializable()
class Setlist {
  final int? id;
  final String name;
  final DateTime? eventDate;
  final String? notes;
  final DateTime creationDate;
  final DateTime modificationDate;

  Setlist({
    this.id,
    required this.name,
    this.eventDate,
    this.notes,
    required this.creationDate,
    required this.modificationDate,
  });

  factory Setlist.fromJson(Map<String, dynamic> json) => _$SetlistFromJson(json);
  Map<String, dynamic> toJson() => _$SetlistToJson(this);
}

@JsonSerializable()
class SetlistSong {
  final int? id;
  final int setlistId;
  final int songId;
  final int order;
  final int transpositionSemitones;
  final int? customCapo;

  SetlistSong({
    this.id,
    required this.setlistId,
    required this.songId,
    required this.order,
    this.transpositionSemitones = 0,
    this.customCapo,
  });

  factory SetlistSong.fromJson(Map<String, dynamic> json) => _$SetlistSongFromJson(json);
  Map<String, dynamic> toJson() => _$SetlistSongToJson(this);
}