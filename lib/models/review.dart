import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final List<String> imageUrls;
  final double rating;
  final String comment;
  final String occasion;
  final String place;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.imageUrls,
    required this.rating,
    required this.comment,
    required this.occasion,
    required this.place,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    comment: json['comment'] ?? '',
    occasion: json['occasion'] ?? '',
    place: json['place'] ?? '',
    createdAt:
        json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'imageUrls': imageUrls,
    'rating': rating,
    'comment': comment,
    'occasion': occasion,
    'place': place,
    'createdAt': createdAt.toIso8601String(),
  };
}
