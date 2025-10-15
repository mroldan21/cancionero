import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
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

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}