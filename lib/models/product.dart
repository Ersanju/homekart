import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homekart/models/review.dart';

import 'extra_attributes.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final List<String> subCategoryIds;
  final String productType;
  final List<String> imageUrls;
  final List<String> tags;
  final bool isAvailable;
  final int stockQuantity;
  final int popularityScore;
  final List<String> productDescription;
  final List<String> careInstruction;
  final List<String> deliveryInformation;
  final ExtraAttributes? extraAttributes;
  final List<Review> reviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subCategoryIds,
    required this.productType,
    required this.imageUrls,
    required this.tags,
    required this.isAvailable,
    required this.stockQuantity,
    required this.popularityScore,
    required this.productDescription,
    required this.careInstruction,
    required this.deliveryInformation,
    required this.extraAttributes,
    required this.reviews,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return Product(
      id: json['id'],
      name: json['name'],
      categoryId: json['categoryId'],
      subCategoryIds: List<String>.from(json['subCategoryIds']),
      productType: json['productType'],
      imageUrls: List<String>.from(json['imageUrls']),
      tags: List<String>.from(json['tags']),
      isAvailable: json['isAvailable'],
      stockQuantity: json['stockQuantity'],
      popularityScore: json['popularityScore'],
      productDescription: List<String>.from(json['productDescription']),
      careInstruction: List<String>.from(json['careInstruction']),
      deliveryInformation: List<String>.from(json['deliveryInformation']),
      extraAttributes: json['extraAttributes'] != null
          ? ExtraAttributes.fromJson(json['extraAttributes'])
          : null,
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e))
          .toList() ??
          [],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      createdBy: json['createdBy'] ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'subCategoryIds': subCategoryIds,
    'productType': productType,
    'imageUrls': imageUrls,
    'tags': tags,
    'isAvailable': isAvailable,
    'stockQuantity': stockQuantity,
    'popularityScore': popularityScore,
    'productDescription': productDescription,
    'careInstruction': careInstruction,
    'deliveryInformation': deliveryInformation,
    'extraAttributes': extraAttributes?.toJson(),
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

}
