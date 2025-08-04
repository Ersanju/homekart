import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppAuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;

  AppAuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchUserDataFromFirestore();
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  String get userId => _user?.uid ?? '';

  Map<String, dynamic>? get userData => _userData;

  Future<void> _fetchUserDataFromFirestore() async {
    if (_user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
    }
  }

  /// Call this after login or app start to sync wishlist
  Future<List<String>> fetchWishlistIds() async {
    if (_user == null) return [];
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();
      return List<String>.from(doc.data()?['wishlistProductIds'] ?? []);
    } catch (e) {
      debugPrint('Failed to fetch wishlist: $e');
      return [];
    }
  }

  Future<void> refreshUserData() async {
    await _fetchUserDataFromFirestore();
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }

  void updateProfileImage(String url) {
    if (_userData != null) {
      _userData!['profileImageUrl'] = url;
      notifyListeners();
    }
  }
}
