import 'card_message.dart';

class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final String variant;
  final double price;

  final String? cakeMessage;
  final CardMessage? cardMessage;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.price,
    this.cakeMessage,
    this.cardMessage,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      quantity: json['quantity'],
      variant: json['variant'],
      price: (json['price'] as num).toDouble(),
      cakeMessage: json['cakeMessage'],
      cardMessage:
          json['cardMessage'] != null
              ? CardMessage.fromJson(
                Map<String, dynamic>.from(json['cardMessage']),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'quantity': quantity,
    'variant': variant,
    'price': price,
    if (cakeMessage != null) 'cakeMessage': cakeMessage,
    if (cardMessage != null) 'cardMessage': cardMessage!.toJson(),
  };

  CartItem copyWith({
    int? quantity,
    String? cakeMessage,
    CardMessage? cardMessage,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      quantity: quantity ?? this.quantity,
      variant: variant,
      price: price,
      cakeMessage: cakeMessage ?? this.cakeMessage,
      cardMessage: cardMessage ?? this.cardMessage,
    );
  }

  static CartItem empty() => CartItem(
    productId: '',
    productName: '',
    productImage: '',
    quantity: 0,
    variant: '',
    price: 0.0,
  );
}
