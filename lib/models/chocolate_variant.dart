class ChocolateVariant {
  final String sku;
  final double weightInGrams;
  final int quantity;
  final double price;
  final double? oldPrice;
  final int stockQuantity;
  final bool isAvailable;

  ChocolateVariant({
    required this.sku,
    required this.weightInGrams,
    required this.quantity,
    required this.price,
    this.oldPrice,
    required this.stockQuantity,
    required this.isAvailable,
  });

  factory ChocolateVariant.fromJson(Map<String, dynamic> json) =>
      ChocolateVariant(
        sku: json['sku'],
        weightInGrams: (json['weightInGrams'] as num).toDouble(),
        quantity: json['quantity'],
        price: (json['price'] as num).toDouble(),
        oldPrice:
        json['oldPrice'] != null ? (json['oldPrice'] as num).toDouble() : null,
        stockQuantity: json['stockQuantity'],
        isAvailable: json['isAvailable'],
      );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'weightInGrams': weightInGrams,
    'quantity': quantity,
    'price': price,
    if (oldPrice != null) 'oldPrice': oldPrice,
    'stockQuantity': stockQuantity,
    'isAvailable': isAvailable,
  };
}