import 'package:flutter/material.dart';

class CartBottomBar extends StatelessWidget {
  final int total;
  final VoidCallback onViewPriceDetails;
  final VoidCallback? onProceed;

  const CartBottomBar({
    super.key,
    required this.total,
    required this.onViewPriceDetails,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onViewPriceDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "View price details",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onProceed,
            child: const Text(
              "Proceed",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
