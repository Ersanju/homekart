import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_address.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> items;
  final UserAddress address;
  final DateTime deliveryDate;
  final String deliveryTime;
  final String status;
  final String paymentMethod;
  final String paymentId;
  final double amount;
  final Timestamp createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.address,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.status,
    required this.paymentMethod,
    required this.paymentId,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items,
      'address': address.toJson(),
      'deliveryDate': deliveryDate.toIso8601String(),
      'deliveryTime': deliveryTime,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'amount': amount,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'],
      userId: json['userId'],
      items: List<Map<String, dynamic>>.from(json['items']),
      address: UserAddress.fromJson(json['address']),
      deliveryDate: DateTime.parse(json['deliveryDate']),
      deliveryTime: json['deliveryTime'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      paymentId: json['paymentId'],
      amount: (json['amount'] as num).toDouble(),
      createdAt: json['createdAt'],
    );
  }
}
