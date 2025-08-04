import 'package:homekart/models/variant.dart';

class CakeAttribute {
  final List<Variant> variants;
  final bool isEgglessAvailable;

  CakeAttribute({
    required this.variants,
    required this.isEgglessAvailable,
  });

  factory CakeAttribute.fromJson(Map<String, dynamic> json) => CakeAttribute(
    variants:
    (json['variants'] as List).map((e) => Variant.fromJson(e)).toList(),
    isEgglessAvailable: json['isEgglessAvailable'],
  );

  Map<String, dynamic> toJson() => {
    'variants': variants.map((e) => e.toJson()).toList(),
    'isEgglessAvailable': isEgglessAvailable,
  };
}