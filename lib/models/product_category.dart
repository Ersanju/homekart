import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final String? categoryId; // Empty if it's a top-level category
  final String imageUrl;
  final String description;
  final int priority; // for display sorting
  final bool active;
  final DateTime createdAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.priority,
    required this.active,
    required this.createdAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId'],
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 0,
      active: json['active'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'description': description,
      'priority': priority,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductCategory.fromMap(String id, Map<String, dynamic> json) {
    return ProductCategory(
      id: id,
      name: json['name'] ?? '',
      categoryId: json['categoryId'],
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 0,
      active: json['active'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}