import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class MyOrdersPage extends StatelessWidget {
  final String userId;
  const MyOrdersPage({super.key, required this.userId});

  Future<List<OrderModel>> _fetchOrders() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return OrderModel.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMainImage(List<dynamic> items) {
    // Priority: cake first
    for (var item in items) {
      if ((item['productName'] ?? '').toString().toLowerCase().contains('cake')) {
        return item['productImage'] ?? '';
      }
    }
    // Otherwise, fallback to first item's image
    return items.isNotEmpty ? (items[0]['productImage'] ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final mainImage = _getMainImage(order.items);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsPage(order: order),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main image + Info + Status
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                mainImage,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order #${order.orderId}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${order.amount}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Placed on ${order.createdAt.toDate().toLocal().toString().split(' ')[0]}",
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Horizontal product thumbnails excluding main image
                        if (order.items.length > 1) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 55,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: order.items
                                  .where((item) =>
                              item['productImage'] != null &&
                                  item['productImage'] != mainImage)
                                  .length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                final filteredItems = order.items
                                    .where((item) =>
                                item['productImage'] != null &&
                                    item['productImage'] != mainImage)
                                    .toList();

                                final product = filteredItems[i];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    product['productImage'] ?? '',
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 55,
                                      height: 55,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order.orderId}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Order Header ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${order.status}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Placed on: ${_formatDate(order.createdAt.toDate())}",
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text(currencyFormat.format(order.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Product Items ----------
            const Text(
              "Items",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) {
              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item['productImage'] ?? '',
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text("Qty: ${item['quantity']}"),
                  trailing: Text(
                    currencyFormat.format(item['price']),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

// ---------- Delivery Address ----------
            _buildSectionTitle("Delivery Address"),
            _infoContainer(
              Text(
                "${order.address.name}\n"
                    "${order.address.street}, ${order.address.area}\n"
                    "${order.address.city}, ${order.address.state} - ${order.address.pinCode}\n"
                    "${order.address.country}",
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

// ---------- Payment Info ----------
            _buildSectionTitle("Payment Info"),
            _infoContainer(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Payment Method: ${order.paymentMethod}",
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                  if (order.paymentId.isNotEmpty)
                    Text("Payment ID: ${order.paymentId}",
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),

// ---------- Delivery Info ----------
            _buildSectionTitle("Delivery Info"),
            _infoContainer(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Delivery Date: ${_formatDate(order.deliveryDate)}",
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                  Text("Delivery Time: ${order.deliveryTime}",
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _infoContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

}




