class DecorationAttribute {
  final String decorationType;
  final String? theme;
  final String? colorScheme;
  final String? color;
  final String? size;
  final String? material;
  final int? durationInHours;
  final double price;
  final String sku;

  DecorationAttribute({
    required this.decorationType,
    this.theme,
    this.colorScheme,
    this.color,
    this.size,
    this.material,
    this.durationInHours,
    required this.price,
    required this.sku,
  });

  factory DecorationAttribute.fromJson(Map<String, dynamic> json) => DecorationAttribute(
    decorationType: json['decorationType'],
    theme: json['theme'],
    colorScheme: json['colorScheme'],
    color: json['color'],
    size: json['size'],
    material: json['material'],
    durationInHours: json['durationInHours'],
    price: (json['price'] as num).toDouble(),
    sku: json['sku'],
  );

  Map<String, dynamic> toJson() => {
    'decorationType': decorationType,
    'theme': theme,
    'colorScheme': colorScheme,
    'color': color,
    'size': size,
    'material': material,
    'durationInHours': durationInHours,
    'price': price,
    'sku': sku,
  };
}
