class Variant {
  final String sku;
  final String weight;
  final int tier;
  final double price;
  final double? oldPrice;
  final int stockQuantity;
  final bool isAvailable;

  Variant({
    required this.sku,
    required this.weight,
    required this.tier,
    required this.price,
    this.oldPrice,
    required this.stockQuantity,
    required this.isAvailable,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
    sku: json['sku'],
    weight: json['weight'],
    tier: json['tier'],
    price: (json['price'] as num).toDouble(),
    oldPrice:
    json['oldPrice'] != null ? (json['oldPrice'] as num).toDouble() : null,
    stockQuantity: json['stockQuantity'],
    isAvailable: json['isAvailable'],
  );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'weight': weight,
    'tier': tier,
    'price': price,
    if (oldPrice != null) 'oldPrice': oldPrice,
    'stockQuantity': stockQuantity,
    'isAvailable': isAvailable,
  };
}