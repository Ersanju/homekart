class GiftAttribute {
  final String type;
  final String size;
  final String color;
  final String material;
  final String? personalizedMessage;
  final double price;
  final String sku;

  GiftAttribute({
    required this.type,
    required this.size,
    required this.color,
    required this.material,
    this.personalizedMessage,
    required this.price,
    required this.sku,
  });

  factory GiftAttribute.fromJson(Map<String, dynamic> json) => GiftAttribute(
    type: json['type'],
    size: json['size'],
    color: json['color'],
    material: json['material'],
    personalizedMessage: json['personalizedMessage'],
    price: (json['price'] as num).toDouble(),
    sku: json['sku'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'size': size,
    'color': color,
    'material': material,
    'personalizedMessage': personalizedMessage,
    'price': price,
    'sku': sku,
  };
}
