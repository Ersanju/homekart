import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../home/chocolate_product_detail_page.dart';
import '../home/product_detail_page.dart';

class CartItemWidget extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback? onCakeMessageTap;
  final String? cakeMessage;
  final VoidCallback? onCardMessageTap;
  final Map<String, dynamic>? cardMessageData;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    this.onCakeMessageTap,
    this.cakeMessage,
    this.onCardMessageTap,
    this.cardMessageData,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  Timer? _repeatTimer;

  void _startRepeating(Function callback) {
    callback();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      callback();
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                GestureDetector(
                  onTap: () {
                    if (widget.item.productId.startsWith('sub_cat_cake')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailPage(
                                productId: widget.item.productId,
                              ),
                        ),
                      );
                    } else if (widget.item.productId.startsWith(
                      'sub_cat_chocolate',
                    )) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChocolateProductDetailPage(
                                productId: widget.item.productId,
                              ),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.item.productImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Product Info & Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease or Delete
                            GestureDetector(
                              onTap: () {
                                // Single tap: delete if quantity == 1, or decrease
                                widget.onDecrease();
                              },
                              onLongPressStart: (_) {
                                // Long press: decrease but stop at 1
                                if (widget.item.quantity > 1) {
                                  _startRepeating(() {
                                    if (widget.item.quantity > 1) {
                                      widget.onDecrease();
                                    } else {
                                      _stopRepeating();
                                    }
                                  });
                                }
                              },
                              onLongPressEnd: (_) => _stopRepeating(),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  widget.item.quantity == 1
                                      ? Icons.delete_outline
                                      : Icons.remove,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Quantity Display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                widget.item.quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Increase
                            GestureDetector(
                              onTapDown:
                                  (_) => _startRepeating(widget.onIncrease),
                              onTapUp: (_) => _stopRepeating(),
                              onTapCancel: _stopRepeating,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🎂 Cake Message Tile
            if (widget.onCakeMessageTap != null)
              buildMessageTile(
                icon: Icons.cake_outlined,
                title:
                    widget.cakeMessage != null
                        ? "Edit Cake Message"
                        : "Message on Cake",
                subtitle: widget.cakeMessage,
                onTap: widget.onCakeMessageTap!,
              ),

            // 💌 Free Card Tile
            if (widget.onCardMessageTap != null)
              buildMessageTile(
                icon: Icons.card_giftcard_outlined,
                title:
                    widget.cardMessageData != null
                        ? "Edit Greeting Card"
                        : "Add Free Greeting Card",
                subtitle:
                    widget.cardMessageData != null
                        ? "${widget.cardMessageData!['occasion']}: ${widget.cardMessageData!['message']}"
                        : null,
                onTap: widget.onCardMessageTap!,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle.length > 50
                            ? "${subtitle.substring(0, 50)}..."
                            : subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
