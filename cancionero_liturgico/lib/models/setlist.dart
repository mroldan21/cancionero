import 'package:cancionero_liturgico/models/song.dart';

class SetlistItem {
  final Song song;
  final int order;
  final int transposition; // Nuevo campo, transposición personalizada en semitonos
  final int? capo;         // Nuevo campo, capo personalizado (puede ser nulo si no se usa)

  SetlistItem({
    required this.song,
    required this.order,
    this.transposition = 0, // Valor por defecto
    this.capo,              // Valor por defecto nulo
  });
}