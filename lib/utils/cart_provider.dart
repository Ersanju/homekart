import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/card_message.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  final Map<String, String> _cakeMessages = {};
  final Map<String, Map<String, dynamic>> _cardMessages = {};

  int _couponDiscount = 0;
  String _couponMessage = '';
  bool _couponApplied = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  Map<String, String> get cakeMessages => _cakeMessages;

  Map<String, Map<String, dynamic>> get cardMessages => _cardMessages;

  int get couponDiscount => _couponDiscount;

  String get couponMessage => _couponMessage;

  bool get couponApplied => _couponApplied;

  User? get user => FirebaseAuth.instance.currentUser;

  CartProvider() {
    _loadCart();
  }

  double get rawProductTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  int get productPrice => rawProductTotal.toInt();

  int get discount {
    if (productPrice > 1000) return 100;
    if (productPrice > 500) return 50;
    return 0;
  }

  int get deliveryCharge => productPrice > 500 ? 0 : 19;

  int get convenienceCharge => productPrice > 500 ? 0 : 39;

  int get subtotal =>
      (productPrice - discount - couponDiscount)
          .clamp(0, double.infinity)
          .toInt();

  int get total => subtotal + deliveryCharge + convenienceCharge;

  void applyCoupon(String code) {
    final normalizedCode = code.trim().toUpperCase();

    if (_couponApplied) {
      _couponMessage = "✅ Coupon already applied.";
      notifyListeners();
      return;
    }

    if (normalizedCode == "JOY50") {
      _couponDiscount = 50;
      _couponMessage = "🎉 Coupon applied! ₹50 off.";
      _couponApplied = true;
    } else {
      _couponMessage = "❌ Invalid coupon code.";
      _couponDiscount = 0;
      _couponApplied = false;
    }

    notifyListeners();
  }

  int getQty(String variantId) {
    return _cartItems
        .firstWhere(
          (item) => item.variant == variantId,
          orElse: () => CartItem.empty(),
        )
        .quantity;
  }

  Future<void> addItem(
    String variantId, {
    required String productId,
    required String productName,
    required String productImage,
    required double price,
  }) async {
    if (user == null) return;

    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 1,
      );
    } else {
      _cartItems.add(
        CartItem(
          productId: productId,
          productName: productName,
          productImage: productImage,
          quantity: 1,
          variant: variantId,
          price: price,
        ),
      );
    }

    await _saveCartToFirestore();
    notifyListeners();
  }

  Future<void> removeItem(String variantId) async {
    if (user == null) return;

    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index == -1) return;

    final currentItem = _cartItems[index];

    if (currentItem.quantity <= 1) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    await _saveCartToFirestore();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _cakeMessages.clear();
    _cardMessages.clear();
    await _saveCartToFirestore();
    notifyListeners();
  }

  Future<void> _loadCart() async {
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      final data = doc.data();
      final items =
          (data?['cartItems'] as List<dynamic>? ?? [])
              .map((e) => CartItem.fromJson(e))
              .toList();

      _cartItems
        ..clear()
        ..addAll(items);

      _cakeMessages.clear();
      _cardMessages.clear();

      for (var e in items) {
        if (e.cakeMessage != null && e.cakeMessage!.isNotEmpty) {
          _cakeMessages[e.productId] = e.cakeMessage!;
        }
        if (e.cardMessage != null) {
          _cardMessages[e.productId] = e.cardMessage!.toJson();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load cart: $e");
    }
  }

  Future<void> _saveCartToFirestore() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'cartItems': _cartItems.map((e) => e.toJson()).toList()});
    } catch (e) {
      debugPrint("Failed to save cart: $e");
    }
  }

  void setCart(List<CartItem> items) {
    _cartItems
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void setQty(String variantId, int qty) {
    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      if (qty > 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: qty);
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<void> updateCakeMessage(String variantId, String message) async {
    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index == -1) return;

    _cartItems[index] = _cartItems[index].copyWith(cakeMessage: message);
    _cakeMessages[_cartItems[index].productId] = message;

    await _saveCartToFirestore();
    notifyListeners();
  }

  Future<void> updateCardMessage(
    String variantId,
    CardMessage cardMessage,
  ) async {
    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index == -1) return;

    _cartItems[index] = _cartItems[index].copyWith(cardMessage: cardMessage);
    _cardMessages[_cartItems[index].productId] = cardMessage.toJson();

    await _saveCartToFirestore();
    notifyListeners();
  }
}
