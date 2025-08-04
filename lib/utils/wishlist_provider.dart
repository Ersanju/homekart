import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider extends ChangeNotifier {
  final List<String> _wishlistProductIds = [];

  List<String> get wishlistProductIds => _wishlistProductIds;

  User? get user => FirebaseAuth.instance.currentUser;

  WishlistProvider() {
    _loadWishlist(); // optional auto-load
  }

  bool isWishlisted(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  Future<void> toggleWishlist(String productId) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    if (_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }

    await userRef.update({
      'wishlistProductIds': List<String>.from(_wishlistProductIds),
    });
    notifyListeners();
  }

  Future<void> removeFromWishlist(String productId) async {
    if (user == null) return;

    _wishlistProductIds.remove(productId);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'wishlistProductIds': List<String>.from(_wishlistProductIds),
    });
    notifyListeners();
  }

  /// Initial load or refresh after login
  Future<void> _loadWishlist() async {
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      final ids = List<String>.from(doc.data()?['wishlistProductIds'] ?? []);
      _wishlistProductIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading wishlist: $e");
    }
  }

  /// Use this from outside after login
  void setWishlist(List<String> ids) {
    _wishlistProductIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }
}
