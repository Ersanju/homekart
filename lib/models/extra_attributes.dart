import 'package:homekart/models/toy_attribute.dart';

import 'cake_attribute.dart';
import 'chocolate_attribute.dart';
import 'decoration_attribute.dart';
import 'gift_attribute.dart';

class ExtraAttributes {
  final CakeAttribute? cakeAttribute;
  final ToyAttribute? toyAttribute;
  final GiftAttribute? giftAttribute;
  final ChocolateAttribute? chocolateAttribute;
  final DecorationAttribute? decorationAttribute;

  ExtraAttributes({
    this.cakeAttribute,
    this.toyAttribute,
    this.giftAttribute,
    this.chocolateAttribute,
    this.decorationAttribute,
  });

  factory ExtraAttributes.fromJson(Map<String, dynamic> json) => ExtraAttributes(
    cakeAttribute: json['cakeAttribute'] != null
        ? CakeAttribute.fromJson(json['cakeAttribute'])
        : null,
    toyAttribute: json['toyAttribute'] != null
        ? ToyAttribute.fromJson(json['toyAttribute'])
        : null,
    giftAttribute: json['giftAttribute'] != null
        ? GiftAttribute.fromJson(json['giftAttribute'])
        : null,
    chocolateAttribute: json['chocolateAttribute'] != null
        ? ChocolateAttribute.fromJson(json['chocolateAttribute'])
        : null,
    decorationAttribute: json['decorationAttribute'] != null
        ? DecorationAttribute.fromJson(json['decorationAttribute'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    if (cakeAttribute != null) 'cakeAttribute': cakeAttribute!.toJson(),
    if (toyAttribute != null) 'toyAttribute': toyAttribute!.toJson(),
    if (giftAttribute != null) 'giftAttribute': giftAttribute!.toJson(),
    if (chocolateAttribute != null)
      'chocolateAttribute': chocolateAttribute!.toJson(),
    if (decorationAttribute != null)
      'decorationAttribute': decorationAttribute!.toJson(),
  };
}